# PlayerDeath.gd
# Attach as a child node of Player.
# Watches Player_Global_Data.p_curr_health and triggers death → main menu.

class_name PlayerDeath
extends Node

# ─────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────
## Path to your main menu scene.
@export var main_menu_scene: String = "res://scenes/ui/menus/intro-menus/main-menu.tscn"
## Delay in seconds before scene changes — use to match death animation length.
@export var death_delay: float = 1.5

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var _dead: bool = false

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _process(_delta: float) -> void:
	if _dead:
		return
	if Player_Global_Data.p_curr_health <= 0.0:
		_trigger_death()

# ─────────────────────────────────────────
# DEATH
# ─────────────────────────────────────────
func _trigger_death() -> void:
	_dead = true
	Player_Global_Data.p_curr_health = 0.0
	Player_Global_Data.p_moveable = false
	Player_Global_Data.is_casting = false
	#Player_Global_Data.combat_mode = false

	await get_tree().create_timer(death_delay).timeout
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	# Reset state clean for next session
	Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health
	Player_Global_Data.p_curr_mana   = Player_Global_Data.p_max_mana
	Player_Global_Data.p_moveable    = true

	get_tree().change_scene_to_file(main_menu_scene)
