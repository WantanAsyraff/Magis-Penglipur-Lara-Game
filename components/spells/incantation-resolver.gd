class_name IncantationResolver extends RefCounted
enum Strategy { IMMEDIATE, CONFIRMATION, DELAYED, CHAINED }
signal changed
var validation_errors: PackedStringArray = []
var strategy: Strategy = Strategy.CHAINED
var delay_seconds: float = 0.35
var sequence: Array[String] = []
var _root: Dictionary = {}
var _node: Dictionary = {}
var _pending: SpellData
var _elapsed: float = 0.0

func rebuild(spells: Array[SpellData]) -> void:
	_root = {}
	validation_errors.clear()
	var ordered := spells.duplicate()
	ordered.sort_custom(func(a, b): return a != null and (b == null or a.spell_id < b.spell_id))
	for spell in ordered:
		if spell == null:
			continue
		var node := _root
		for key in spell.spell_incantation:
			if not node.has(key):
				node[key] = {}
			node = node[key]
		if node.has("spell") and node.spell != spell:
			validation_errors.append("Duplicate equipped incantation: " + ",".join(spell.spell_incantation))
		else:
			node.spell = spell
	clear()

func clear() -> void:
	sequence.clear()
	_node = _root
	_pending = null
	_elapsed = 0
	changed.emit()

func accepts(key: String) -> bool:
	return _node.has(key) or _can_restart_chain(key)

func _can_restart_chain(key: String) -> bool:
	return strategy == Strategy.CHAINED and _node.has("spell") and _root.has(key)

func has_extension() -> bool:
	for key in _node:
		if key != "spell":
			return true
	return false

func push(key: String) -> SpellData:
	# Continue an equipped longer combo when possible; otherwise a completed
	# combo may immediately start another without dropping its first arrow.
	if not _node.has(key) and _can_restart_chain(key):
		clear()
	if not accepts(key):
		clear()
		return null
	_node = _node[key]
	sequence.append(key)
	_pending = _node.get("spell")
	_elapsed = 0
	changed.emit()
	if _pending == null or strategy == Strategy.CONFIRMATION:
		return null
	if strategy == Strategy.DELAYED and has_extension():
		return null
	var result := _pending
	_pending = null
	if strategy == Strategy.IMMEDIATE or not has_extension():
		clear()
	return result

func confirm() -> SpellData:
	var result := _pending
	clear()
	return result

func tick(delta: float) -> SpellData:
	if strategy != Strategy.DELAYED or _pending == null:
		return null
	_elapsed += delta
	if _elapsed >= maxf(delay_seconds, 0.05):
		return confirm()
	return null

# Trie snapshots contain resource references, but never expose mutable trie containers.
func get_sequence_snapshot() -> Array[String]:
	return sequence.duplicate()

func get_valid_next_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in ["up", "down", "left", "right"]:
		if accepts(key): keys.append(key)
	return keys

func get_current_exact_match() -> SpellData:
	return _node.get("spell")

func get_matching_spells() -> Array[SpellData]:
	var result: Array[SpellData] = []
	_collect(_node, result)
	result.sort_custom(func(a, b):
		if a.spell_incantation.size() != b.spell_incantation.size():
			return a.spell_incantation.size() < b.spell_incantation.size()
		if a.spell_name != b.spell_name: return a.spell_name < b.spell_name
		return a.spell_id < b.spell_id)
	return result

func get_reachable_chain_spells() -> Array[SpellData]:
	var result := get_matching_spells()
	result.erase(get_current_exact_match())
	return result

func _collect(node: Dictionary, result: Array[SpellData]) -> void:
	if node.has("spell"): result.append(node.spell)
	for key in ["up", "down", "left", "right"]:
		if node.has(key): _collect(node[key], result)

func starts_new_sequence(key: String) -> bool:
	return sequence.is_empty() or (not _node.has(key) and _can_restart_chain(key))

func get_continuation_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in ["up", "down", "left", "right"]:
		if _node.has(key): keys.append(key)
	return keys

func get_restart_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in get_valid_next_keys():
		if not _node.has(key): keys.append(key)
	return keys
