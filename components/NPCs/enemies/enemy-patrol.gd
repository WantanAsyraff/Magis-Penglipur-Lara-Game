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

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var home_position: Vector2 = Vector2.ZERO
var patrol_direction: int = 1
var _jump_cooldown: float = 0.0
var _is_jumping: bool = false
var _direction_lock: float = 0.0
var _home_initialised: bool = false
var _grounded_once: bool = false     # don't patrol until first landing

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

	# Wait until the enemy has touched the floor at least once before doing anything
	if not _grounded_once:
		if enemy.is_on_floor():
			_grounded_once = true
			home_position = enemy.global_position  # re-snap home to actual landed position
		return

	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta
	if _direction_lock > 0.0:
		_direction_lock -= delta

	if _is_jumping:
		if enemy.is_on_floor():
			_is_jumping = false
		elif _has_environment_wall(enemy.velocity.x >= 0.0):
			_is_jumping = false
			_flip_direction()

func patrol_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	# Stay still until grounded — prevents spawn tweak
	if not _grounded_once:
		return 0.0

	if _has_environment_wall(facing_right) and enemy.is_on_floor() and _jump_cooldown <= 0.0:
		_do_wall_jump(enemy)
		return enemy.velocity.x

	if _direction_lock <= 0.0:
		var at_edge  = not _has_ground_ahead(facing_right) and enemy.is_on_floor()
		var at_limit = abs(enemy.global_position.x - home_position.x) >= patrol_range
		var hit_enemy := _has_enemy_ahead(facing_right)

		if at_edge or at_limit or hit_enemy:
			_flip_direction()
			return 0.0  # one dead frame to let the lock settle before moving

	return patrol_direction * get_parent().move_speed

## Returns desired velocity.x, or NAN if arrived home.
func return_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	if not _grounded_once:
		return 0.0

	if abs(enemy.global_position.x - home_position.x) < 8.0:
		return NAN

	var dir = sign(home_position.x - enemy.global_position.x)

	if _has_environment_wall(facing_right) and enemy.is_on_floor() and _jump_cooldown <= 0.0:
		_do_wall_jump(enemy)
		return enemy.velocity.x

	if _direction_lock <= 0.0:
		var hit_enemy := _has_enemy_ahead(facing_right)
		var at_cliff  := not _has_ground_ahead(facing_right) and enemy.is_on_floor()

		if hit_enemy or at_cliff:
			_flip_direction()
			home_position.x = get_parent().global_position.x + (-dir * patrol_range)
			return 0.0

	return dir * get_parent().move_speed

func get_patrol_direction() -> int:
	return patrol_direction

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────

func _flip_direction() -> void:
	patrol_direction *= -1
	_direction_lock = 0.4

func _has_environment_wall(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(24.0 * dir, 0.0)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	var collider := rc.get_collider()
	if collider is CollisionObject2D:
		return (collider.collision_layer & ENVIRONMENT_LAYER) != 0
	return true

func _has_enemy_ahead(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(24.0 * dir, 0.0)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	return rc.get_collider() is Enemy

func _has_ground_ahead(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(24.0 * dir, 30.0)
	rc.force_raycast_update()
	return rc.is_colliding()

func _do_wall_jump(enemy: CharacterBody2D) -> void:
	enemy.velocity.y = wall_jump_velocity
	_jump_cooldown = 0.8
	_is_jumping = true
