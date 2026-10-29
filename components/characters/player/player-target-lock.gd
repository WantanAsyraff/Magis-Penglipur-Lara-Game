class_name PlayerTargetLock extends Node2D
## Stable automatic selection; Q walks the current distance-sorted candidate list.
@export var target_range: float = 1200.0
## Brief LOS/range flicker must not bounce selection between enemies.
const LOSS_GRACE: float = 0.15
var _lost_for: float = 0.0
const RETICLE = preload("res://components/characters/player/player-target-reticle.gd")
var reticle: Node2D
var locked_target: Node2D
var actor: Player

func _ready() -> void:
	actor = get_parent() as Player


func active() -> bool:
	if not is_instance_valid(actor): return false
	var local := not actor.multiplayer.has_multiplayer_peer() or actor.is_multiplayer_authority()
	return local and actor.combat_mode and not actor.get_meta("combat_dead", false) and Player_Global_Data.is_alive()

func _live_hostile(target: Variant) -> bool:
	if not is_instance_valid(target) or not target is Node2D or not target.is_inside_tree() or target.is_queued_for_deletion() or target == actor: return false
	if target.get_meta("combat_dead", false) or not target.is_visible_in_tree() or target.get_node_or_null("HitboxComponent") == null: return false
	return CombatFactions.relation(actor,target) < 0

func eligible(target: Variant) -> bool:
	if not _live_hostile(target) or actor.global_position.distance_to(target.global_position) > target_range: return false
	var exclusions: Array[RID] = [actor.get_rid()]
	if target is CollisionObject2D: exclusions.append(target.get_rid())
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position, aim_point(target), 16, exclusions)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func candidates() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("combat_target"):
		if node is Node2D and eligible(node): result.append(node)
	result.sort_custom(func(a: Node2D,b: Node2D):
		var da := actor.global_position.distance_squared_to(a.global_position)
		var db := actor.global_position.distance_squared_to(b.global_position)
		return str(a.get_path()) < str(b.get_path()) if is_equal_approx(da,db) else da < db)
	return result

func refresh() -> void:
	if not active():
		locked_target = null
		_lost_for = 0.0
	elif eligible(locked_target):
		_lost_for = 0.0
	elif not _live_hostile(locked_target) or _lost_for >= LOSS_GRACE:
		var choices := candidates()
		locked_target = choices[0] if not choices.is_empty() else null
		_lost_for = 0.0
	_sync_reticle()

func can_cycle() -> bool:
	if not active() or get_tree().paused or Dialogic.current_timeline != null or QuestOfferDialog.is_open(): return false
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return false
	return true

func cycle_target() -> void:
	if not can_cycle(): return
	_lost_for = 0.0
	var choices := candidates()
	if choices.is_empty(): locked_target = null
	else: locked_target = choices[(choices.find(locked_target)+1) % choices.size()]
	_sync_reticle()

static func aim_point(target: Node2D) -> Vector2:
	return SpellDelivery.target_bounds(target).get_center()

func _physics_process(delta: float) -> void:
	if active() and _live_hostile(locked_target) and not eligible(locked_target):
		_lost_for += delta
	refresh()

func _process(_delta: float) -> void:
	if is_instance_valid(reticle):
		reticle.visible = can_cycle() and is_instance_valid(locked_target)
		reticle.queue_redraw()

func _sync_reticle() -> void:
	if not is_instance_valid(locked_target):
		if is_instance_valid(reticle): reticle.queue_free()
		reticle = null
		return
	if not is_instance_valid(reticle) or reticle.is_queued_for_deletion():
		reticle = RETICLE.new()
		locked_target.add_child(reticle)
	elif reticle.get_parent() != locked_target:
		reticle.reparent(locked_target,false)
		reticle.transform = Transform2D.IDENTITY
		reticle.reset_physics_interpolation()
	reticle.visible = can_cycle()
	reticle.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_instance_valid(reticle): reticle.hide()

func _exit_tree() -> void:
	if is_instance_valid(reticle): reticle.queue_free()
