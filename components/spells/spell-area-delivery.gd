class_name SpellAreaDelivery extends Node2D
var context: SpellCastContext
var elapsed: float = 0.0
var until_tick: float = 0.0
var beam_segments: Array[Vector2] = []
func _physics_process(delta: float) -> void:
	if context == null or not context.can_execute() or not SpellExecutor.is_authoritative(context.caster):
		queue_free(); return
	elapsed += delta
	until_tick -= delta
	if elapsed > context.spell.area_duration:
		queue_free(); return
	if until_tick <= 0:
		until_tick += maxf(context.spell.area_tick_interval, 0.05)
		var delivery := LegacySpellAdapter.delivery_for(context.spell)
		var hit := false
		if delivery == SpellData.Delivery.BEAM:
			hit = cast_beams()
		else:
			hit = SpellDelivery.apply_area(context, global_position)
		if hit and delivery == SpellData.Delivery.TRAP: queue_free()
	queue_redraw()

func cast_beams() -> bool:
	beam_segments.clear()
	var visited: Array[Node2D] = []
	var applied := false
	for angle in context.spell.beam_angles.slice(0, 5):
		var origin := global_position
		var heading := context.direction.rotated(deg_to_rad(angle))
		var distance := context.spell.target_range
		var exclusions: Array[RID] = []
		for bounce in 4:
			var end := origin + heading * distance
			var query := PhysicsRayQueryParameters2D.create(origin, end, 16, exclusions)
			var collision := get_world_2d().direct_space_state.intersect_ray(query)
			if not collision.is_empty(): end = collision.position
			beam_segments.append_array([origin - global_position, end - global_position])
			for h in get_tree().get_nodes_in_group("hitbox"):
				var target := h.get_parent() as Node2D
				if target == null or target in visited or not SpellDelivery.can_target(context, target): continue
				var closest := Geometry2D.get_closest_point_to_segment(target.global_position, origin, end)
				if closest.distance_to(target.global_position) <= context.spell.beam_width / 2:
					visited.append(target)
					applied = SpellExecutor.new().execute(context, target) or applied
			if collision.is_empty() or not collision.collider.has_meta("optical_interface"): break
			distance -= origin.distance_to(end)
			if distance <= 0: break
			var turn := float(collision.collider.get_meta("optical_interface"))
			heading = heading.bounce(collision.normal) if is_zero_approx(turn) else heading.rotated(deg_to_rad(turn))
			exclusions.append(collision.rid)
			origin = end + heading * 2
	return applied

func _draw() -> void:
	if context == null: return
	var spell := context.spell
	var c := spell.spell_colour
	if spell.delivery == SpellData.Delivery.BEAM:
		for i in range(0, beam_segments.size(), 2):
			draw_line(beam_segments[i], beam_segments[i + 1], Color(c, 0.35), spell.beam_width)
			draw_line(beam_segments[i], beam_segments[i + 1], c, 2)
	else:
		draw_circle(Vector2.ZERO, spell.aoe_spell_radius, Color(c, 0.12))
		draw_arc(Vector2.ZERO, spell.aoe_spell_radius, 0, TAU * maxf(0, 1 - elapsed / spell.area_duration), 48, c, 3)
		if spell.delivery == SpellData.Delivery.TRAP:
			draw_line(Vector2(-18, -18), Vector2(18, 18), c, 3)
			draw_line(Vector2(-18, 18), Vector2(18, -18), c, 3)
