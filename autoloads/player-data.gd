class_name PlayerData extends Node

# In PlayerData (add extends Node first!):
signal mana_changed(new_value: int)
signal health_changed(new_value: int)

var p_name: String
var p_role: String

var p_curr_ringgit: String
var p_mood: String
var combat_mode: String

var p_position: Vector2
var p_moveable: bool = true
var p_jumpable: bool = true
var p_visible: bool = true
var p_invincible: bool = false
var p_hidden: bool = false


var p_speed: float = 900
var p_jump_height: float = -930.0
var p_max_health: int = 100
var p_curr_health: int = p_max_health
var p_max_mana: int = 250
var p_curr_mana: int = p_max_mana
var p_size: float = 1

var current_field: String
var current_major: String
var current_minor: String


var learned_spells: Array[SpellData] = []

func add_spell(spell: SpellData):
	if learned_spells.has(spell):
		return
	learned_spells.append(spell)
	print("Global learned spell:", spell.spell_name)

func add_spells(spells: Array[SpellData]):
	for s in spells:
		add_spell(s)
