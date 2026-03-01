class_name NpcCasterBrain
extends Node

# ─────────────────────────────────────────
# STATES
# ─────────────────────────────────────────
enum State {
	IDLE,
	EVALUATE,
	CASTING,
	REACTING,
	RECOVERING
}

var current_state: State = State.IDLE

# ─────────────────────────────────────────
# REFS
# ─────────────────────────────────────────
var _npc: SpellCasterNPC
var _data: NPCSpellcasterData
var _handler: NpcSpellHandler

# ─────────────────────────────────────────
# TIMERS
# ─────────────────────────────────────────
var _state_timer: float = 0.0
var _react_timer: float = 0.0

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_npc = get_parent() as SpellCasterNPC
	_data = _npc.data
	_handler = _npc.spell_handler

func _process(delta: float) -> void:
	if not _npc.is_alive:
		return
	_state_timer -= delta
	_tick_state(delta)

# ─────────────────────────────────────────
# STATE MACHINE
# ─────────────────────────────────────────
func _tick_state(delta: float) -> void:
	match current_state:
		State.IDLE:       _state_idle(delta)
		State.EVALUATE:   _state_evaluate()
		State.CASTING:    _state_casting(delta)
		State.REACTING:   _state_reacting(delta)
		State.RECOVERING: _state_recovering(delta)

func _enter_state(new_state: State) -> void:
	current_state = new_state
	_state_timer = 0.0

# ─────────────────────────────────────────
# IDLE — watches player, waits to engage
# ─────────────────────────────────────────
func _state_idle(_delta: float) -> void:
	_npc.stop_moving()
	if _npc.player and _state_timer <= 0.0:
		_enter_state(State.EVALUATE)

# ─────────────────────────────────────────
# EVALUATE — picks what to do next
# Difficulty scales here via magis_comprehension
# ─────────────────────────────────────────
func _state_evaluate() -> void:
	# Bail into recovering if mana is low
	if _handler.is_low_mana():
		_enter_state(State.RECOVERING)
		return

	# Reposition if too close or too far
	var dist = _npc.get_distance_to_player()
	if dist < _data.too_close_threshold:
		_npc.move_away_from_player(0.0)
		_state_timer = 0.3
		return
	if dist > _data.preferred_range:
		_npc.move_toward_player(0.0)
		_state_timer = 0.3
		return

	_npc.stop_moving()

	if not _handler.is_ready_to_cast():
		return

	# Pick a spell based on comprehension level
	var spell = _pick_spell()
	if spell:
		_cast_spell(spell)

# ─────────────────────────────────────────
# SPELL PICKING — smarter at higher levels
# ─────────────────────────────────────────
func _pick_spell() -> SpellData:
	var pool = _handler.get_affordable_spells()
	if pool.is_empty():
		return null

	match _data.magis_comprehension:
		"Novice":
			# Pure random
			return pool[randi() % pool.size()]

		"Intermediate":
			# Situational — prefer ranged if far, melee if close
			var dist = _npc.get_distance_to_player()
			var preferred: Array[SpellData] = []
			for spell in pool:
				if dist > _data.preferred_range and spell.spell_manifest == SpellData.SpellManifest.RANGED:
					preferred.append(spell)
				elif dist <= _data.preferred_range and spell.spell_manifest == SpellData.SpellManifest.MELEE:
					preferred.append(spell)
			if not preferred.is_empty():
				return preferred[randi() % preferred.size()]
			return pool[randi() % pool.size()]

		"Advanced":
			# Counter player's last archetype
			var counter = _get_counter_spell(pool)
			if counter and randf() < _data.counter_chance:
				return counter
			# Otherwise situational
			return _pick_spell_intermediate(pool)

		"Expert":
			# Combo — if combo chance passes, pick a spell that chains well
			if randf() < _data.combo_chance:
				return _pick_combo_opener(pool)
			# Otherwise counter or situational
			var counter = _get_counter_spell(pool)
			if counter and randf() < _data.counter_chance:
				return counter
			return _pick_spell_intermediate(pool)

	return pool[randi() % pool.size()]

func _pick_spell_intermediate(pool: Array[SpellData]) -> SpellData:
	var dist = _npc.get_distance_to_player()
	var preferred: Array[SpellData] = []
	for spell in pool:
		if dist > _data.preferred_range and spell.spell_manifest == SpellData.SpellManifest.RANGED:
			preferred.append(spell)
		elif dist <= _data.preferred_range and spell.spell_manifest == SpellData.SpellManifest.MELEE:
			preferred.append(spell)
	if not preferred.is_empty():
		return preferred[randi() % preferred.size()]
	return pool[randi() % pool.size()]

func _get_counter_spell(pool: Array[SpellData]) -> SpellData:
	# Counter Al-Nur with Al-Zalam and vice versa
	var player_archetype = _get_player_archetype()
	var counter_archetype = ""
	if player_archetype == "Alnur":
		counter_archetype = "Alzalam"
	elif player_archetype == "Alzalam":
		counter_archetype = "Alnur"

	if counter_archetype == "":
		return null

	var counters: Array[SpellData] = []
	for spell in pool:
		if spell.magis_archetype == counter_archetype:
			counters.append(spell)
	if not counters.is_empty():
		return counters[randi() % counters.size()]
	return null

func _pick_combo_opener(pool: Array[SpellData]) -> SpellData:
	# Prefer IMPAIRMENT first — debuff then damage
	var impairment: Array[SpellData] = []
	for spell in pool:
		if spell.spell_type == SpellData.SpellType.IMPAIRMENT:
			impairment.append(spell)
	if not impairment.is_empty():
		return impairment[randi() % impairment.size()]
	return pool[randi() % pool.size()]

func _get_player_archetype() -> String:
	# Hook into player data if exposed — fallback to empty
	var player = _npc.player
	if player and player.has_method("get_active_archetype"):
		return player.get_active_archetype()
	return ""

# ─────────────────────────────────────────
# CASTING — locked in, wait for handler
# ─────────────────────────────────────────
func _cast_spell(spell: SpellData) -> void:
	_enter_state(State.CASTING)
	_handler.try_cast(spell)
	# Wait for cast_time then return to evaluate
	await get_tree().create_timer(spell.cast_time + _data.cast_delay_max).timeout
	if current_state == State.CASTING:
		_enter_state(State.EVALUATE)

func _state_casting(_delta: float) -> void:
	_npc.stop_moving()   # Stand still while casting

# ─────────────────────────────────────────
# REACTING — dodge or counter incoming
# ─────────────────────────────────────────
func notify_incoming_spell() -> void:
	if randf() < _data.aggression:
		_enter_state(State.REACTING)
		_react_timer = _data.react_window

func _state_reacting(delta: float) -> void:
	_react_timer -= delta
	# Dodge away from player
	_npc.move_away_from_player(delta)
	if _react_timer <= 0.0:
		_enter_state(State.EVALUATE)

# ─────────────────────────────────────────
# RECOVERING — back off, wait for mana
# ─────────────────────────────────────────
func _state_recovering(delta: float) -> void:
	# Keep distance while mana recovers
	var dist = _npc.get_distance_to_player()
	if dist < _data.preferred_range:
		_npc.move_away_from_player(delta)
	else:
		_npc.stop_moving()

	if not _handler.is_low_mana():
		_enter_state(State.EVALUATE)
