class_name DestructionRuntime extends Node2D
## Scene-owned scheduler: no coroutine outlives the world, no recursive explosion dispatch.
signal behavior_executed(event_id: String, index: int)
var jobs: Array[Dictionary] = []
var spawned: Array[WeakRef] = []
var persistent_ids: Dictionary = {}
var total_spawned := 0
const MAX_ACTIVE := 256
static func for_object(object: Node2D) -> DestructionRuntime:
	var world := object.get_parent()
	if world is DestructionRuntime: return world
	while world.get_parent() is Node2D:
		world = world.get_parent()
	var found: DestructionRuntime = world.get_meta("_destruction_runtime") if world.has_meta("_destruction_runtime") else null
	if found: return found
	var runtime := DestructionRuntime.new()
	runtime.name = "DestructionRuntime"
	world.set_meta("_destruction_runtime", runtime)
	if world.is_node_ready(): world.add_child(runtime)
	else:
		world.tree_exiting.connect(runtime._cancel_unattached, CONNECT_ONE_SHOT)
		world.add_child.call_deferred(runtime)
	return runtime
func _cancel_unattached() -> void:
	if not is_inside_tree(): free()
func enqueue(context: DestructionContext, behaviors: Array[DestructionBehavior]) -> void:
	if jobs.size() >= 64: _finished(context); return
	jobs.append({"context": context, "behaviors": behaviors.duplicate(), "index": 0, "wait": -1.0})
func _physics_process(delta: float) -> void:
	var steps := 0
	for job in jobs.duplicate():
		var context: DestructionContext = job.context
		if not context.effects_valid(): jobs.erase(job); continue
		if job.index >= job.behaviors.size(): jobs.erase(job); _finished(context); continue
		var behavior: DestructionBehavior = job.behaviors[job.index]
		if behavior == null or not behavior.enabled:
			job.index += 1; job.wait = -1.0; continue
		if not behavior.validate().is_empty():
			push_warning("Destruction behavior skipped: " + "; ".join(behavior.validate()))
			job.index += 1; job.wait = -1.0; continue
		if job.wait < 0: job.wait = behavior.delay_seconds
		job.wait -= delta
		if job.wait > 0: continue
		if steps >= 32: break
		steps += 1
		behavior.execute(context)
		if not context.valid(): return
		behavior_executed.emit(context.event_id, job.index)
		job.index += 1; job.wait = -1.0
	spawned = spawned.filter(func(ref): return is_instance_valid(ref.get_ref()))
func _finished(context: DestructionContext) -> void:
	var object := context.source_object()
	if is_instance_valid(object):
		var component := object.get_node_or_null("DestructibleComponent") as DestructibleComponent
		if component and component.generation == context.generation: component.behaviors_finished()
func spawn_node(node: Node2D, context: DestructionContext, at: Vector2, lifetime: float = 0, parent: Node = null) -> bool:
	spawned = spawned.filter(func(ref): return is_instance_valid(ref.get_ref()))
	if not context.valid() or spawned.size() >= MAX_ACTIVE or not context.budget.reserve_spawn():
		node.free(); return false
	var destination := parent if is_instance_valid(parent) else self
	destination.add_child(node)
	node.global_position = at
	spawned.append(weakref(node)); total_spawned += 1
	if lifetime > 0:
		var timer := Timer.new(); timer.wait_time = clampf(lifetime, 0.05, 300); timer.one_shot = true
		node.add_child(timer); timer.timeout.connect(node.queue_free); timer.start()
	return true
func safe_spawn_position(scene: PackedScene, desired: Vector2, exclude: Array[RID]) -> bool:
	if scene == null: return false
	var sample := scene.instantiate()
	if not sample is Node2D: sample.free(); return false
	var shapes := sample.find_children("*", "CollisionShape2D", true, false)
	var valid := true
	for shape in shapes:
		if not shape.get_parent() is PhysicsBody2D or shape.shape == null or shape.disabled: continue
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape.shape
		var transform: Transform2D = shape.transform
		var cursor: Node = shape.get_parent()
		while cursor != sample and cursor is Node2D:
			transform = cursor.transform * transform; cursor = cursor.get_parent()
		query.transform = Transform2D(sample.rotation, sample.scale, 0, desired) * transform
		query.collision_mask = 19; query.exclude = exclude
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): valid = false; break
	sample.free()
	return valid
