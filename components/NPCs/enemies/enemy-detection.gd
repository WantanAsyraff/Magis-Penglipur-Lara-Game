# EnemyDetection.gd
# Attach as a child node of Enemy.
# DetectionArea and RayCasts live under Enemy (siblings) — wired in via connect_area().
# Exposes: player, has_line_of_sight(), has_memory()

class_name EnemyDetection
extends Node

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal player_entered
signal player_exited

# ─────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────
@export var sight_memory: float = 2.5

# ─────────────────────────────────────────
# NODE REFS
# ─────────────────────────────────────────
# Raycasts are siblings under Enemy — resolved via unique name from the scene root.
@onready var raycast_right: RayCast2D = %"RayCast2D(Right)"
@onready var raycast_left: RayCast2D = %"RayCast2D(Left)"

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var player: Node = null
var _sight_memory_timer: float = 0.0

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────

## Call from Enemy._ready(), passing $DetectionArea so we don't need it as a child.
func connect_area(area: Area2D) -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

## Call from Enemy._physics_process every frame.
func tick(delta: float) -> void:
	if player != null and has_line_of_sight():
		_sight_memory_timer = sight_memory
	elif _sight_memory_timer > 0.0:
		_sight_memory_timer -= delta

# ─────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────

## True if the player is directly visible via raycast right now.
func has_line_of_sight() -> bool:
	if player == null:
		return false
	var to_player = get_parent().to_local(player.global_position)
	var rc := raycast_right if to_player.x >= 0.0 else raycast_left
	var prev := rc.target_position
	rc.target_position = to_player
	rc.force_raycast_update()
	var result := not rc.is_colliding() or rc.get_collider() == player
	rc.target_position = prev
	return result

## True if the enemy still "remembers" the player after losing sight.
func has_memory() -> bool:
	return _sight_memory_timer > 0.0

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		player_entered.emit()

func _on_body_exited(body: Node) -> void:
	if body == player:
		player_exited.emit()
		# Don't null player here — sight memory handles the fade
