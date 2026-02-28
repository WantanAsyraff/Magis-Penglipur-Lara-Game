extends Node

signal custom_signal_emitted(signal_key: String)
signal combat_mode_changed(is_combat: bool)
signal casting_changed(is_casting: bool)
signal mana_changed(new_value: int)
signal health_changed(new_value: int)
signal spells_updated()

var p_name: String
var p_role: String
var p_curr_ringgit: String
var p_mood: String

var _is_casting := false
var is_casting: bool:
	set(value):
		if _is_casting == value:
			return
		_is_casting = value
		casting_changed.emit(value)
	get:
		return _is_casting

var _combat_mode := false
var combat_mode: bool:
	set(value):
		if _combat_mode == value:
			return
		_combat_mode = value
		combat_mode_changed.emit(value)
	get:
		return _combat_mode

var p_position: Vector2
var p_moveable: bool = true
var p_jumpable: bool = true
var p_visible: bool = true
var p_invincible: bool = false
var p_hidden: bool = false
var p_speed: float = 950
var p_jump_height: float = -1800.0

var p_max_health: int = 100
var p_curr_health: int = p_max_health:
	set(value):
		p_curr_health = clamp(value, 0, p_max_health)
		health_changed.emit(p_curr_health)

var p_max_mana: int = 250
var p_curr_mana: int = p_max_mana:
	set(value):
		p_curr_mana = clamp(value, 0, p_max_mana)
		mana_changed.emit(p_curr_mana)

var p_size: float = 1
var current_field: String
var current_major: String
var current_minor: String
var learned_spells: Array[SpellData] = []

func add_spell(spell: SpellData) -> void:
	if learned_spells.has(spell):
		return
	learned_spells.append(spell)
	print("Global learned spell: ", spell.spell_name)
	spells_updated.emit()

func add_spells(spells: Array[SpellData]) -> void:
	for s in spells:
		if learned_spells.has(s):
			continue
		learned_spells.append(s)
		print("Global learned spell: ", s.spell_name)
	spells_updated.emit()

func remove_spell(spell: SpellData) -> void:
	if not learned_spells.has(spell):
		return
	learned_spells.erase(spell)
	print("Global removed spell: ", spell.spell_name)
	spells_updated.emit()

func has_spell(spell: SpellData) -> bool:
	return learned_spells.has(spell)

func consume_mana(amount: int) -> bool:
	if p_curr_mana < amount:
		return false
	p_curr_mana -= amount
	return true

func restore_mana(amount: int) -> void:
	p_curr_mana += amount

func take_damage(amount: int) -> void:
	if p_invincible:
		return
	p_curr_health -= amount

func restore_health(amount: int) -> void:
	p_curr_health += amount

func is_alive() -> bool:
	return p_curr_health > 0

func reset() -> void:
	p_curr_health = p_max_health
	p_curr_mana = p_max_mana
	learned_spells.clear()
	is_casting = false
	combat_mode = false
	spells_updated.emit()
