# GodMode.gd
# Attach to a Node2D child of the Player scene.
# Binds to the "god_mode" input action (add it in Project → Input Map).
#
# While active:
#   - Player flies freely (gravity off, full 8-directional movement)
#   - Movement speed is multiplied by GOD_SPEED_MULTIPLIER
#   - All incoming damage and status effects are blocked
#   - A visible label indicates god mode is on
class_name GodMode
extends Node

# -------------------------
# CONFIG
# -------------------------
const GOD_SPEED_MULTIPLIER: float = 4.0
const FLY_FRICTION: float = 8.0  # how quickly velocity bleeds off when no input

# -------------------------
# STATE
# -------------------------
var _active: bool = false
var _player: Player = null
var _original_collision_mask: int = 0

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	# Expect to be a direct child of Player
	_player = get_parent() as Player
	if not _player:
		push_error("GodMode: parent is not a Player node.")
		return
	_setup_label()

func _setup_label() -> void:
	var label := Label.new()
	label.name = "GodLabel"
	label.text = "✦ GOD MODE ✦"
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_font_size_override("font_size", 14)
	# Position above the player sprite — adjust y offset to taste
	label.position = Vector2(-52, -96)
	label.visible = false
	add_child(label)

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("god_mode"):
		_toggle()

# -------------------------
# TOGGLE
# -------------------------
func _toggle() -> void:
	_active = not _active
	var label := get_node_or_null("GodLabel") as Label
	if label:
		label.visible = _active
	if _active:
		_on_enter()
	else:
		_on_exit()

func _on_enter() -> void:
	if not _player:
		return
	# Zero out all velocity on entry so there's no lurch
	_player.velocity = Vector2.ZERO
	# Store and strip collision so nothing can hurt the player
	_original_collision_mask = _player.collision_mask
	_player.collision_mask = 0
	# Block all hitbox damage
	_player.hitbox.set_invincible(true)
	Player_Global_Data.p_moveable = true

func _on_exit() -> void:
	if not _player:
		return
	# Restore collision
	_player.collision_mask = _original_collision_mask
	# Re-enable damage
	_player.hitbox.set_invincible(false)
	# Bleed off any lingering fly velocity so landing feels clean
	_player.velocity = Vector2.ZERO

# -------------------------
# PHYSICS
# -------------------------
func _physics_process(delta: float) -> void:
	if not _active or not _player:
		return
	if not Player_Global_Data.p_moveable:
		return

	# Read 8-directional input
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var fly_speed := _player.SPEED * GOD_SPEED_MULTIPLIER

	if dir != Vector2.ZERO:
		_player.velocity = dir * fly_speed
	else:
		# Smooth stop on X — feels natural for horizontal deceleration.
		# Hard zero on Y every frame — prevents gravity accumulated by
		# Player._apply_gravity() from slowly drifting the player downward
		# when no directional input is held. Node execution order is not
		# guaranteed, so we can't rely on our velocity write overriding
		# whatever Player._physics_process already added to velocity.y.
		_player.velocity.x = move_toward(_player.velocity.x, 0.0, fly_speed * FLY_FRICTION * delta)
		_player.velocity.y = 0.0
