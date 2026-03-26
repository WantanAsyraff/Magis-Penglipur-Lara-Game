# MagnetComponent.gd
extends Node
class_name MagnetComponent

@export var pull_speed: float = 600.0
@export var detection_range: float = 200.0

var _parent: DroppedItem
var _target: Node2D = null

func init_component(parent: DroppedItem) -> void:
	_parent = parent

func _physics_process(delta: float) -> void:
	# Only start pulling if the item is ready to be picked up
	var pickup = _parent.find_child("ItemPickupComponent")
	if not pickup or not pickup._is_collectible:
		return

	if not _target:
		_find_player()
	else:
		_pull_to_player(delta)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if _parent.global_position.distance_to(p.global_position) < detection_range:
			_target = p

func _pull_to_player(delta: float) -> void:
	var dir = (_target.global_position - _parent.global_position).normalized()
	# Overwrite the physics velocity to fly toward the player
	_parent.velocity = _parent.velocity.lerp(dir * pull_speed, 10.0 * delta)
