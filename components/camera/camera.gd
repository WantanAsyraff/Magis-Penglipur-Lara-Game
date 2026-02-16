class_name Camera extends Camera2D

@onready var combatUI: Control = %UserInterfaceCombat
@onready var overworldUI: Control = %UserInterfaceOverworld
@onready var pauseMenuUI: Control = %PauseMenu

func _ready():
	add_to_group("camera")
	
	# Enable smooth camera following
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	
	# Connect signals
	Player_Global_Data.combat_mode_changed.connect(_on_combat_mode_changed)
	
	# Set initial UI state
	pauseMenuUI.visible = false
	_on_combat_mode_changed(Player_Global_Data.combat_mode)

func _physics_process(_delta):
	_handle_pause_input()

# -------------------------
# PAUSE
# -------------------------
func _handle_pause_input() -> void:
	if not Input.is_action_just_pressed("paused"):
		return
	_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = !get_tree().paused
	_refresh_ui_visibility()

func unpause() -> void:
	get_tree().paused = false
	_refresh_ui_visibility()

func _refresh_ui_visibility() -> void:
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
func _on_combat_mode_changed(is_combat: bool):
	if get_tree().paused:
		return
	
	combatUI.visible = is_combat
	overworldUI.visible = !is_combat
