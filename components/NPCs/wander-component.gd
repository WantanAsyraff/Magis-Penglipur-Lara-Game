# WanderComponent.gd
# Attach as a child of any CharacterBody2D.
# No NavigationAgent2D required!
class_name WanderComponent
extends Node2D

@export var move_speed: float = 60.0
@export var wander_range_x: float = 100.0 # Total distance left/right from origin
@export var pause_duration: float = 2.0

var _body: CharacterBody2D
var _origin_x: float
var _target_x: float
var _pause_timer: float = 0.0

enum State { IDLE, MOVING }
var _state: State = State.IDLE

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	# Wait for spawn to finish, then lock the starting X position
	await get_tree().process_frame
	_origin_x = _body.global_position.x
	_pick_new_target()

func _physics_process(delta: float) -> void:
	# Stop everything if dialogue is open
	if not Player_Global_Data.p_moveable:
		_body.velocity = Vector2.ZERO
		return

	match _state:
		State.IDLE:
			_pause_timer -= delta
			if _pause_timer <= 0:
				_pick_new_target()
		
		State.MOVING:
			var current_x = _body.global_position.x
			var direction = sign(_target_x - current_x)
			
			# Check if we've arrived (within 2 pixels)
			if abs(current_x - _target_x) < 2.0:
				_body.velocity = Vector2.ZERO
				_state = State.IDLE
				_pause_timer = pause_duration
			else:
				_body.velocity.x = direction * move_speed
				_body.move_and_slide()

func _pick_new_target() -> void:
	# Randomly pick a spot between (Origin - Range) and (Origin + Range)
	_target_x = _origin_x + randf_range(-wander_range_x, wander_range_x)
	_state = State.MOVING

func set_origin(pos: Vector2) -> void:
	_origin_x = pos.x
