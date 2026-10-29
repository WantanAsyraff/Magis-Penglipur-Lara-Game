class_name PlayerEnvironmentTarget extends Node
const RETICLE = preload("res://components/characters/player/player-target-reticle.gd")
var selected: Node2D
var reticle: Node2D
var actor: Player
func _ready() -> void:
	actor = get_parent() as Player
func eligible(target: Variant) -> bool:
	if not is_instance_valid(target) or not target is Node2D or target.is_queued_for_deletion() or target.get_meta("combat_dead",false): return false
	var descriptor := target.get_node_or_null("EnvironmentalTarget") as EnvironmentalTarget
	if descriptor == null or not descriptor.targetable or CombatFactions.relation(actor,target) < 0 or actor.global_position.distance_to(target.global_position) > 1000: return false
	var exclude: Array[RID] = [actor.get_rid()]
	if target is CollisionObject2D: exclude.append(target.get_rid())
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position,SpellDelivery.target_bounds(target).get_center(),16,exclude)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
func allowed() -> bool:
	if not is_instance_valid(actor) or get_tree().paused or actor.get_meta("combat_dead",false) or Dialogic.current_timeline != null or QuestOfferDialog.is_open(): return false
	for phone in get_tree().get_nodes_in_group("phone_ui"):
		if phone.phone_selected: return false
	return not actor.multiplayer.has_multiplayer_peer() or actor.is_multiplayer_authority()
func cycle() -> void:
	if not allowed(): return
	var candidates: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("environmental_targets"):
		if eligible(node): candidates.append(node)
	candidates.sort_custom(func(a,b):
		var da: float = actor.global_position.distance_squared_to(a.global_position)
		var db: float = actor.global_position.distance_squared_to(b.global_position)
		return str(a.get_path()) < str(b.get_path()) if is_equal_approx(da,db) else da < db)
	var index := candidates.find(selected)+1
	selected = candidates[index] if index < candidates.size() else null
	_sync()
func clear() -> void:
	selected = null; _sync()
func current() -> Node2D:
	if not eligible(selected): clear()
	return selected
func _physics_process(_delta: float) -> void:
	current()
	if is_instance_valid(reticle): reticle.visible = allowed()
func _sync() -> void:
	if is_instance_valid(reticle): reticle.queue_free()
	reticle = null
	if not is_instance_valid(selected): return
	reticle = RETICLE.new(); reticle.set("binding_action",&"environment_target"); reticle.set("caption","DEVICE"); reticle.set("tint",Color(.4,.9,1))
	selected.add_child(reticle)
func _exit_tree() -> void:
	if is_instance_valid(reticle): reticle.queue_free()
