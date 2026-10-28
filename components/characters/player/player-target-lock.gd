class_name PlayerTargetLock extends Node2D
## Stable automatic selection; Q walks the current distance-sorted candidate list.
@export var target_range: float = 1200.0
var locked_target: Node2D
var actor: Player

func _ready() -> void:
	actor = get_parent() as Player
	z_index = 100

func active() -> bool:
	if not is_instance_valid(actor): return false
	var local := not actor.multiplayer.has_multiplayer_peer() or actor.is_multiplayer_authority()
	return local and actor.combat_mode and not actor.get_meta("combat_dead", false) and Player_Global_Data.is_alive()

func eligible(target: Variant) -> bool:
	if not is_instance_valid(target) or not target is Node2D or not target.is_inside_tree() or target.is_queued_for_deletion() or target == actor: return false
	if target.get_meta("combat_dead", false) or not target.is_visible_in_tree() or target.get_node_or_null("HitboxComponent") == null: return false
	if CombatFactions.relation(actor,target) >= 0 or actor.global_position.distance_to(target.global_position) > target_range: return false
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
	elif not eligible(locked_target):
		var choices := candidates()
		locked_target = choices[0] if not choices.is_empty() else null
	queue_redraw()

func can_cycle() -> bool:
	if not active() or get_tree().paused or Dialogic.current_timeline != null or QuestOfferDialog.is_open(): return false
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return false
	return true

func cycle_target() -> void:
	if not can_cycle(): return
	var choices := candidates()
	if choices.is_empty(): locked_target = null
	else: locked_target = choices[(choices.find(locked_target)+1) % choices.size()]
	queue_redraw()

static func aim_point(target: Node2D) -> Vector2:
	return SpellDelivery.target_bounds(target).get_center()

func _physics_process(_delta: float) -> void:
	refresh()
	visible = can_cycle() and is_instance_valid(locked_target)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED: hide()

func _draw() -> void:
	if not is_instance_valid(locked_target) or not eligible(locked_target): return
	var rect := SpellDelivery.target_bounds(locked_target).grow(12)
	var start := to_local(rect.position)
	var end := to_local(rect.end)
	var tint := Color(1.0,0.8,0.35)
	for point in [Vector2(start.x,start.y), Vector2(end.x,start.y), Vector2(start.x,end.y), Vector2(end.x,end.y)]:
		var direction := Vector2(1 if point.x == start.x else -1, 1 if point.y == start.y else -1)
		draw_line(point,point+Vector2(18*direction.x,0),tint,3,true)
		draw_line(point,point+Vector2(0,18*direction.y),tint,3,true)
	var key := "Q"
	var events := InputMap.action_get_events("cycle_target")
	if not events.is_empty() and events[0] is InputEventKey:
		key = OS.get_keycode_string(events[0].physical_keycode if events[0].physical_keycode else events[0].keycode)
	draw_string(ThemeDB.fallback_font,start+Vector2(0,-10),"LOCK · %s Next" % key,HORIZONTAL_ALIGNMENT_LEFT,-1,16,tint)
