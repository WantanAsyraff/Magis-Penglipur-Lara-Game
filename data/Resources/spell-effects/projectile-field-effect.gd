class_name ProjectileFieldEffect extends SpellEffectDefinition
enum Mode { REVERSE, ATTRACT, SLOW, CANCEL }
@export var mode: Mode = Mode.REVERSE
@export var radius: float = 150.0
@export var strength: float = 0.3
func accepts(target: Node2D) -> bool:
	return is_instance_valid(target)
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid projectile field"]) if radius <= 0 or radius > 1000 or not is_finite(radius) or strength < 0 or strength > 1 else PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	for item in target.get_tree().get_nodes_in_group("spell_projectile"):
		var p := item as MagicProjectile
		if p == null or p._finished or p.is_queued_for_deletion() or p.cast_context.source_team == context.source_team or p.global_position.distance_to(context.source_position) > radius:
			continue
		match mode:
			Mode.REVERSE:
				if not context.state.has(p.get_instance_id()):
					p.redirect(context, -p.direction)
					context.state[p.get_instance_id()] = true
			Mode.ATTRACT:
				p.direction = p.direction.lerp((context.source_position - p.global_position).normalized(), strength).normalized()
			Mode.SLOW: p.local_speed_factor = minf(p.local_speed_factor, strength); p.slow_remaining = 0.35
			Mode.CANCEL:
				if p.spell_data.has_wave_tag: p.queue_free()
	if mode == Mode.CANCEL:
		for area in target.get_tree().get_nodes_in_group("spell_area"):
			if area.context.source_team != context.source_team and area.context.spell.has_wave_tag and area.global_position.distance_to(context.source_position) <= radius: area.queue_free()
	return true
