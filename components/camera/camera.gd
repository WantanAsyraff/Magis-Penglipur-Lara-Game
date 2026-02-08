class_name Camera extends Camera2D

@onready var combatUI: Control = %UserInterfaceCombat
@onready var overworldUI: Control = %UserInterfaceOverworld

const SCREEN_SIZE := Vector2(1280, 720)

# Camera smoothing and dynamics
@export_group("Camera Follow")
@export var follow_smoothing := 8.0
@export var look_ahead_distance := 100.0
@export var look_ahead_smoothing := 5.0
@export var vertical_offset := -50.0  # Look slightly up

@export_group("Camera Bounds")
@export var use_grid_bounds := false  # Toggle between grid-locked and smooth follow
@export var enable_screen_shake := true

@export_group("Screen Shake")
@export var shake_decay := 5.0

var cur_screen := Vector2(0, 0)
<<<<<<< Updated upstream

func _ready():
	set_as_top_level(true)
	global_position = get_parent().global_position
=======
var _shake_strength := 0.0
var _shake_offset := Vector2.ZERO
var _look_ahead_offset := Vector2.ZERO
var _target_position := Vector2.ZERO

func _ready():
	add_to_group("camera")
>>>>>>> Stashed changes
	
	# Don't set as top level - we want to follow parent
	# but we'll manage position ourselves
	
	# Connect signals
	Player_Global_Data.combat_mode_changed.connect(_on_combat_mode_changed)
	
<<<<<<< Updated upstream
	# 2. Set initial UI state
=======
	# Set initial UI state
	pauseMenuUI.visible = false
>>>>>>> Stashed changes
	_on_combat_mode_changed(Player_Global_Data.combat_mode)
	
	# Initialize target position
	_target_position = get_parent().global_position

<<<<<<< Updated upstream
func _physics_process(_delta):
	# Now only handles the grid-based movement
	var parent_screen : Vector2 = (get_parent().global_position / SCREEN_SIZE).floor()
	if not parent_screen.is_equal_approx(cur_screen):
		_update_screen(parent_screen)

# 3. This runs ONLY when the mode actually changes
=======
func _physics_process(delta):
	_handle_pause_input()
	
	if get_tree().paused:
		return
	
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# Get player velocity for look-ahead
	var player_velocity := Vector2.ZERO
	if parent_node.has_method("get_velocity"):
		player_velocity = parent_node.get_velocity()
	elif "velocity" in parent_node:
		player_velocity = parent_node.velocity
	
	# Calculate look-ahead based on movement direction
	var target_look_ahead := Vector2.ZERO
	if player_velocity.length() > 10.0:
		target_look_ahead.x = sign(player_velocity.x) * look_ahead_distance
	
	_look_ahead_offset = _look_ahead_offset.lerp(target_look_ahead, look_ahead_smoothing * delta)
	
	# Calculate target position
	_target_position = parent_node.global_position + Vector2(0, vertical_offset) + _look_ahead_offset
	
	# Grid-based bounds if enabled
	if use_grid_bounds:
		var parent_screen := (_target_position / SCREEN_SIZE).floor()
		if not parent_screen.is_equal_approx(cur_screen):
			cur_screen = parent_screen
		var grid_target := cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
		_target_position = _target_position.lerp(grid_target, 0.3)
	
	# Smooth follow
	global_position = global_position.lerp(_target_position, follow_smoothing * delta)
	
	# Apply screen shake
	if enable_screen_shake and _shake_strength > 0:
		_shake_strength = max(0.0, _shake_strength - shake_decay * delta)
		_shake_offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		offset = _shake_offset
	else:
		offset = Vector2.ZERO

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
>>>>>>> Stashed changes
func _on_combat_mode_changed(is_combat: bool):
	combatUI.visible = is_combat
	overworldUI.visible = !is_combat

<<<<<<< Updated upstream
func _update_screen(new_screen : Vector2):
	cur_screen = new_screen
	global_position = cur_screen * SCREEN_SIZE + SCREEN_SIZE * 0.5
=======
# -------------------------
# CAMERA EFFECTS
# -------------------------
func apply_shake(strength: float) -> void:
	"""Apply screen shake. Useful for impacts, explosions, etc."""
	_shake_strength = max(_shake_strength, strength)

func set_smoothing_speed(speed: float) -> void:
	"""Temporarily change camera smoothing (e.g., faster for combat)"""
	follow_smoothing = speed

func snap_to_target() -> void:
	"""Instantly snap camera to target position (useful for teleports/scene transitions)"""
	if get_parent():
		global_position = get_parent().global_position + Vector2(0, vertical_offset)
		_target_position = global_position

func get_screen_bounds() -> Rect2:
	"""Returns the current visible screen bounds in world coordinates"""
	var half_size = get_viewport_rect().size * zoom / 2.0
	return Rect2(global_position - half_size, half_size * 2.0)
>>>>>>> Stashed changes
