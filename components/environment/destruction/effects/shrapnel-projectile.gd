class_name DestructionShrapnel extends Node2D
var context: DestructionContext
var definition: ShrapnelBehavior
var velocity := Vector2.ZERO
var age := 0.0
var hit_ids: Dictionary = {}
var excluded: Array[RID] = []
func _ready() -> void:
	add_to_group("destruction_shrapnel")
	var source := context.source_object()
	if source is CollisionObject2D: excluded.append(source.get_rid())
	if definition.shrapnel_texture:
		var sprite := Sprite2D.new(); sprite.texture = definition.shrapnel_texture; add_child(sprite)
func _physics_process(delta: float) -> void:
	if context == null or not context.valid(): queue_free(); return
	age += delta
	if age >= definition.projectile_lifetime: queue_free(); return
	if definition.gravity_enabled: velocity.y += 980 * definition.gravity_scale * delta
	var end := global_position + velocity * delta
	# Swept ray avoids tunneling. Re-query remaining segment for bounded piercing.
	for step in clampi(definition.max_pierces + 1, 1, 9):
		var query := PhysicsRayQueryParameters2D.create(global_position, end, 19, excluded)
		var collision := get_world_2d().direct_space_state.intersect_ray(query)
		if collision.is_empty(): break
		var target := collision.collider as Node2D
		excluded.append(collision.rid)
		if target != null and definition.targets.accepts(context, target) and not hit_ids.has(target.get_instance_id()):
			hit_ids[target.get_instance_id()] = true
			DestructionCombat.hit(context, target, definition.projectile_damage, EnvironmentalDamage.Kind.IMPACT)
			if definition.impact_particles:
				var particles := definition.impact_particles.instantiate()
				if particles is Node2D: context.runtime.spawn_node(particles, context, collision.position, 2.0)
				else: particles.free()
			if not definition.piercing_enabled or hit_ids.size() >= definition.max_pierces: queue_free(); return
		elif target != null and target.collision_layer & 16:
			queue_free(); return
	global_position = end
	rotation = velocity.angle()
	queue_redraw()
func _draw() -> void:
	if definition and definition.shrapnel_texture: return
	draw_colored_polygon(PackedVector2Array([Vector2(7,0),Vector2(-5,-3),Vector2(-3,4)]), Color("ffdda0"))
