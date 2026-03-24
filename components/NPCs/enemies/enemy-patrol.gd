# EnemyPatrol.gd
# Attach as a child node of Enemy.
# Shared raycasts: RayCast2D(Right), RayCast2D(Left) — marked unique (%) under Enemy.
# Call tick(delta) every physics frame from Enemy._physics_process.

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
## Bitmask for Layer 5 (Environment). 2^(5-1) = 16.
const ENVIRONMENT_LAYER: int = 16

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var home_position: Vector2 = Vector2.ZERO
var patrol_direction: int = 1        # 1 = right, -1 = left
var _jump_cooldown: float = 0.0
var _is_jumping: bool = false        # true from jump until landing

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	home_position = get_parent().global_position

# ─────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────

## Call from Enemy._physics_process every frame.
func tick(delta: float, enemy: CharacterBody2D) -> void:
	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta

	# Once airborne from a jump, check if environment is still blocking.
	# If it is, the jump won't clear it — turn around instead.
	if _is_jumping:
		if enemy.is_on_floor():
			_is_jumping = false   # landed cleanly, jump succeeded
		elif _has_environment_wall(enemy.velocity.x >= 0.0):
			# Still hitting environment mid-air — turn around on landing
			_is_jumping = false
			patrol_direction *= -1

## Run one frame of patrol movement. Returns the desired velocity.x.
func patrol_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	var at_edge  = not _has_ground_ahead(facing_right) and enemy.is_on_floor()
	var at_limit = abs(enemy.global_position.x - home_position.x) >= patrol_range

	if _has_environment_wall(facing_right) and enemy.is_on_floor() and _jump_cooldown <= 0.0:
		_do_wall_jump(enemy)
		return enemy.velocity.x  # keep x during jump frame

	if at_edge or at_limit:
		patrol_direction *= -1

	return patrol_direction * get_parent().move_speed

## Run one frame of return-home movement. Returns desired velocity.x.
## Returns NAN if the enemy should stop and go IDLE.
func return_tick(enemy: CharacterBody2D, facing_right: bool) -> float:
	if abs(enemy.global_position.x - home_position.x) < 8.0:
		return NAN  # arrived home

	var dir = sign(home_position.x - enemy.global_position.x)

	if _has_environment_wall(facing_right) and enemy.is_on_floor() and _jump_cooldown <= 0.0:
		_do_wall_jump(enemy)
		return enemy.velocity.x

	# Cliff on the way home — stop rather than walk off
	if not _has_ground_ahead(facing_right) and enemy.is_on_floor():
		return NAN

	return dir * get_parent().move_speed

func get_patrol_direction() -> int:
	return patrol_direction

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────

## True if the raycast ahead hits a collider on the Environment layer (Layer 5).
func _has_environment_wall(facing_right: bool) -> bool:
	var rc  := raycast_right if facing_right else raycast_left
	var dir := 1.0 if facing_right else -1.0
	rc.target_position = Vector2(24.0 * dir, 0.0)
	rc.force_raycast_update()
	if not rc.is_colliding():
		return false
	var collider := rc.get_collider()
	# TileMapLayer and physics bodies both inherit CollisionObject2D
	if collider is CollisionObject2D:
		return (collider.collision_layer & ENVIRONMENT_LAYER) != 0
	# Fallback: treat any unrecognised collider as environment
	return true

func _has_ground_ahead(facing_right: bool) -> bool:
	var rc  = raycast_right if facing_right else raycast_left
	var dir = 1.0 if facing_right else -1.0
	rc.target_position = Vector2(24.0 * dir, 30.0)
	rc.force_raycast_update()
	return rc.is_colliding()

func _do_wall_jump(enemy: CharacterBody2D) -> void:
	enemy.velocity.y = wall_jump_velocity
	_jump_cooldown = 0.8
	_is_jumping = true
