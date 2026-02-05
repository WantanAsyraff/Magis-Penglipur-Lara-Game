class_name Camera extends Camera2D

@onready var combatUI: Control = %UserInterfaceCombat
@onready var overworldUI: Control = %UserInterfaceOverworld
@onready var pauseMenuUI: Control = %PauseMenu

const SCREEN_SIZE := Vector2(1280, 720)
var cur_screen := Vector2(0, 0)
var _was_paused := false

func _ready():
	add_to_group("camera")  # Add to group so pause menu can find it
	set_as_top_level(true)
	global_position = get_parent().global_position
	
	# 1. Connect to the global signal
	Player_Global_Data.combat_mode_changed.connect(_on_combat_mode_changed)
	
	# 2. Set initial UI state
	pauseMenuUI.visible = false
	_on_combat_mode_changed(Player_Global_Data.combat_mode)
	_update_screen(cur_screen)

func _physics_process(_delta):
	_handle_pause_input()
	
	# Now only handles the grid-based movement
	var parent_screen : Vector2 = (get_parent().global_position / SCREEN_SIZE).floor()
	if not parent_screen.is_equal_approx(cur_screen):
		_update_screen(parent_screen)

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

# Public method for pause menu to call
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

# -------------------------
# SCREEN TRACKING
# -------------------------
func _update_screen(new_screen : Vector2):
	cur_screen = new_screen
	global_position = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
