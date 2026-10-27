class_name WanderComponent extends Node2D
@export var move_speed: float = 60
@export var wander_range_x: float = 100
@export var pause_duration: float = 2
@export var stationary: bool = false
var validator: NPCSpawnValidator
var region := Rect2()
var _origin_x: float
var _target_x: float
var _pause_timer: float = 0
var _body: CharacterBody2D
func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	set_origin(_body.global_position)
	if validator == null:
		validator = NPCSpawnValidator.new()
		var collision := _body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision and collision.shape is RectangleShape2D: validator.body_size = collision.shape.size * _body.global_scale.abs()
		region = Rect2(_body.global_position - Vector2(wander_range_x + 100, 400), Vector2(wander_range_x*2 + 200, 800))
func set_origin(pos: Vector2) -> void:
	_origin_x = pos.x
	_target_x = pos.x
func steer(delta: float) -> void:
	_body.velocity.x = 0
	if stationary or not Player_Global_Data.p_moveable or QuestOfferDialog.is_open(): return
	_pause_timer -= delta
	if _pause_timer > 0: return
	if absf(_body.global_position.x - _target_x) < 5:
		_target_x = _origin_x + randf_range(-wander_range_x, wander_range_x)
		_pause_timer = pause_duration
		return
	var next := _body.global_position + Vector2(signf(_target_x - _body.global_position.x)*move_speed*delta, 0)
	var space := _body.get_world_2d().direct_space_state
	var exclude: Array[RID] = [_body.get_rid()]
	if not validator.valid(space, next, region, [], exclude) or not validator.reachable(space, _body.global_position, next, exclude):
		_target_x = _body.global_position.x
		_pause_timer = pause_duration
		return
	for npc in get_tree().get_nodes_in_group("quest_npc"):
		if npc != _body and npc.global_position.distance_to(next) < validator.minimum_separation: return
	_body.velocity.x = signf(_target_x - _body.global_position.x)*move_speed
