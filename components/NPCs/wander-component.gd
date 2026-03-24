# WanderComponent.gd
# Attach as a child of any CharacterBody2D.
# Uses NavigationAgent2D for obstacle-aware wandering.
# Requires a NavigationRegion2D in the scene with a baked navmesh.
#
# NPC scene structure:
#   NPC (CharacterBody2D)
#     ├── WanderComponent
#     │     └── NavigationAgent2D   ← must be a direct child
#     └── ...
class_name WanderComponent
extends Node2D

# -------------------------
# EXPORTS
# -------------------------
@export var move_speed: float = 60.0
@export var wander_radius: float = 120.0
# Min/max seconds to wait before picking a new destination
@export var pause_min: float = 1.5
@export var pause_max: float = 4.0
# How many times to retry finding a valid navmesh point before giving up
@export var max_target_retries: int = 5
# How close the NPC needs to get before considering the target reached
@export var arrival_threshold: float = 8.0

# -------------------------
# NODES
# -------------------------
@onready var _agent: NavigationAgent2D = %NavigationAgent2D

# -------------------------
# STATE
# -------------------------
var _body: CharacterBody2D = null
var _origin: Vector2
var _pause_timer: float = 0.0
var _is_paused: bool = true
var _suspended: bool = false

enum State { PAUSED, MOVING }
var _state: State = State.PAUSED

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if not _body:
		push_error("WanderComponent: parent must be a CharacterBody2D.")
		return

	if not _agent:
		push_error("WanderComponent: missing NavigationAgent2D child.")
		return

	_agent.path_desired_distance = arrival_threshold
	_agent.target_desired_distance = arrival_threshold

	_origin = _body.global_position

	# NavigationAgent needs one frame before the navmesh is ready
	await get_tree().physics_frame
	_start_pause(randf_range(0.2, 1.0))

# -------------------------
# TICK — called from NPC._physics_process()
# -------------------------
func tick(delta: float) -> void:
	if _suspended or not _body or not _agent:
		return

	match _state:
		State.PAUSED:
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_try_pick_target()

		State.MOVING:
			if _agent.is_navigation_finished():
				_start_pause(randf_range(pause_min, pause_max))
				return

			var next := _agent.get_next_path_position()
			var direction := (next - _body.global_position).normalized()
			_body.velocity = direction * move_speed
			_body.move_and_slide()

# -------------------------
# TARGET SELECTION
# -------------------------
func _try_pick_target() -> void:
	var map := _body.get_world_2d().navigation_map
	var found := false

	for _i in max_target_retries:
		var candidate := _random_point_in_radius()
		var closest := NavigationServer2D.map_get_closest_point(map, candidate)
		# Accept if the closest navmesh point is within 32px of our candidate
		if closest.distance_to(candidate) < 32.0:
			_agent.target_position = closest
			_state = State.MOVING
			found = true
			break

	if not found:
		# No valid point found — pause and try again next cycle
		_start_pause(randf_range(pause_min, pause_max))

func _random_point_in_radius() -> Vector2:
	var angle := randf() * TAU
	var distance := randf() * wander_radius
	return _origin + Vector2(cos(angle), sin(angle)) * distance

# -------------------------
# PAUSE
# -------------------------
func _start_pause(duration: float) -> void:
	_state = State.PAUSED
	_pause_timer = duration
	if _body:
		_body.velocity = Vector2.ZERO

# -------------------------
# CONTROL API
# -------------------------
func suspend() -> void:
	_suspended = true
	if _body:
		_body.velocity = Vector2.ZERO

func resume() -> void:
	_suspended = false
	_start_pause(randf_range(0.5, 1.5))

func set_origin(pos: Vector2) -> void:
	_origin = pos
