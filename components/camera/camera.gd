class_name PlayerCamera
extends Camera2D

@onready var combatUI: Control = %UserInterfaceCombat
@onready var overworldUI: Control = %UserInterfaceOverworld
@onready var pauseMenuUI: Control = %PauseMenu

func _ready() -> void:
	add_to_group("camera")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0

	Player_Global_Data.combat_mode_changed.connect(_on_combat_mode_changed)

	pauseMenuUI.visible = false
	_on_combat_mode_changed(Player_Global_Data.combat_mode)

func _process(_delta: float) -> void:
	_handle_pause_input()

# -------------------------
# PAUSE
# -------------------------
func _handle_pause_input() -> void:
	if SaveManager.loading: return
	if not Input.is_action_just_pressed("paused"):
		return
	_toggle_pause()

func _toggle_pause() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = !get_tree().paused
	_refresh_ui_visibility()

func unpause() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	_refresh_ui_visibility()

func _refresh_ui_visibility() -> void:
	if not is_inside_tree():
		return
	var is_paused := get_tree().paused
	pauseMenuUI.visible = is_paused

	if is_paused:
		combatUI.visible = false
		overworldUI.visible = false
	else:
		_on_combat_mode_changed(Player_Global_Data.combat_mode)

# -------------------------
# COMBAT MODE
# -------------------------
func _on_combat_mode_changed(is_combat: bool) -> void:
	if not is_inside_tree():
		return
	if get_tree().paused:
		return

	combatUI.visible = is_combat
	overworldUI.visible = !is_combat
