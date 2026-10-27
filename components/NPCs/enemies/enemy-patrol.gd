# EnemyPatrol.gd
class_name EnemyPatrol
extends Node

# ─────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────
@export var patrol_range: float = 120.0
@export var wall_jump_velocity: float = -260.0

# ─────────────────────────────────────────
# NODE REFS
# ─────────────────────────────────────────
@onready var raycast_right: RayCast2D = %"RayCast2D(Right)"
@onready var raycast_left: RayCast2D = %"RayCast2D(Left)"

# ─────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────
const ENVIRONMENT_LAYER: int = 16
const WALL_RAY_DIST: float = 24.0
const GROUND_RAY_DIST: float = 24.0
const GROUND_RAY_DROP: float = 30.0

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var home_position: Vector2 = Vector2.ZERO
var patrol_direction: int = 1
var _jump_cooldown: float = 0.0
var _is_jumping: bool = false
var _direction_lock: float = 0.0
var _home_initialised: bool = false
var _grounded_once: bool = false

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	pass

# ─────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────

func tick(delta: float, enemy: CharacterBody2D) -> void:
	if not _home_initialised:
		home_position = enemy.global_position
		_home_initialised = true

	if not _grounded_once:
		if enemy.is_on_floor():
			_grounded_once = true
			home_position = enemy.global_position
		return

	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta
	if _direction_lock > 0.0:
		_direction_lock -= delta

	if _is_jumping:
		if enemy.is_on_floor():
			_is_jumping = false
		elif _wall_check(enemy.velocity.x >= 0.0):
			_is_jumping = false
			_flip_direction()

	# Jump whenever a wall is blocking the current facing direction.
	# Runs every tick so it fires from any state (IDLE, PATROL, CHASE, etc.)
	if enemy.is_on_floor() and _jump_cooldown <= 0.0:
		var facing_right: bool = patrol_direction > 0
		if _wall_check(facing_right):
			_do_wall_jump(enemy)

func patrol_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	if not _grounded_once:
		return 0.0

	if _direction_lock <= 0.0:
		var at_edge   = not _ground_check(facing_right) and enemy.is_on_floor()
		var at_limit  = abs(enemy.global_position.x - home_position.x) >= patrol_range
		var hit_enemy = _enemy_check(facing_right)

		if at_edge or at_limit or hit_enemy:
			_flip_direction()
			return 0.0

	return patrol_direction * get_parent().move_speed

## Returns desired velocity.x, or NAN if arrived home.
func return_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	if not _grounded_once:
		return 0.0

	if abs(enemy.global_position.x - home_position.x) < 8.0:
		return NAN

	var dir = sign(home_position.x - enemy.global_position.x)

	if _direction_lock <= 0.0:
		var hit_enemy := _enemy_check(facing_right)
		var at_cliff  := not _ground_check(facing_right) and enemy.is_on_floor()

		if hit_enemy or at_cliff:
			_flip_direction()
			home_position.x = get_parent().global_position.x + (-dir * patrol_range)
			return 0.0

	return dir * get_parent().move_speed

func get_patrol_direction() -> int:
	return patrol_direction

# ─────────────────────────────────────────
# INTERNAL
# Each check sets its own target_position before calling force_raycast_update()
# so the three checks never overwrite each other's results mid-frame.
# ─────────────────────────────────────────

func _flip_direction() -> void:
	patrol_direction *= -1
	_direction_lock = 0.4

## Purely horizontal ray — detects environment walls only.
func _wall_check(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(WALL_RAY_DIST * dir, 0.0)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	var collider := rc.get_collider()
	var hit_env := false
	if collider is CollisionObject2D:
		hit_env = (collider.collision_layer & ENVIRONMENT_LAYER) != 0
	else:
		hit_env = true

	return hit_env

## Diagonal-down ray — checks for ground ahead of the enemy's foot.
## Validates the hit normal points upward so wall sides don't count as ground.
func _ground_check(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(GROUND_RAY_DIST * dir, GROUND_RAY_DROP)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	# Floor normals point up (y < 0 in Godot). Wall normals point sideways (y ≈ 0).
	# Reject wall-side hits so the enemy correctly treats them as edges/cliffs.
	var normal := rc.get_collision_normal()
	return normal.y < -0.5

## Horizontal ray — detects another Enemy in the way (for collision avoidance).
func _enemy_check(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(WALL_RAY_DIST * dir, 0.0)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	return rc.get_collider() is Enemy

func _do_wall_jump(enemy: CharacterBody2D) -> void:
	enemy.velocity.y = wall_jump_velocity
	_jump_cooldown = 0.8
	_is_jumping = true
