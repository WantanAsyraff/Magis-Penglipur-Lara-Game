extends Node
# Note: Ensure this is named 'Player_Global_Data' in your Project Settings > Autoload
signal custom_signal_emitted(signal_key: String)
signal combat_mode_changed(is_combat: bool)
signal mana_changed(new_value: int)
signal health_changed(new_value: int)
signal spells_updated()

var p_name: String
var p_role: String
var p_curr_ringgit: String
var p_mood: String
var is_casting := false

# SETTER: This automatically triggers the signal whenever the value changes
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

var p_speed: float = 900
var p_jump_height: float = -1600.0
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

func add_spell(spell: SpellData):
	if learned_spells.has(spell):
		return
	learned_spells.append(spell)
	spells_updated.emit()
	print("Global learned spell:", spell.spell_name)

func add_spells(spells: Array[SpellData]):
	for s in spells:
		add_spell(s)
