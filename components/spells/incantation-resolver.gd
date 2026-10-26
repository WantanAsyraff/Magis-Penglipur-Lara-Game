class_name IncantationResolver extends RefCounted
enum Strategy { IMMEDIATE, CONFIRMATION, DELAYED, CHAINED }
var strategy: Strategy = Strategy.CHAINED
var delay_seconds: float = 0.35
var sequence: Array[String] = []
var _root: Dictionary = {}
var _node: Dictionary = {}
var _pending: SpellData
var _elapsed: float = 0.0

func rebuild(spells: Array[SpellData]) -> void:
	_root = {}
	for spell in spells:
		if spell == null:
			continue
		var node := _root
		for key in spell.spell_incantation:
			if not node.has(key):
				node[key] = {}
			node = node[key]
		if not node.has("spell"):
			node.spell = spell
	clear()

func clear() -> void:
	sequence.clear()
	_node = _root
	_pending = null
	_elapsed = 0

func accepts(key: String) -> bool:
	return _node.has(key)

func has_extension() -> bool:
	for key in _node:
		if key != "spell":
			return true
	return false

func push(key: String) -> SpellData:
	if not accepts(key):
		clear()
		return null
	_node = _node[key]
	sequence.append(key)
	_pending = _node.get("spell")
	_elapsed = 0
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
