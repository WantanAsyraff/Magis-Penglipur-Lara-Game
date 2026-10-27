class_name SpellConstruct extends StaticBody2D
var context: SpellCastContext
var elapsed: float = 0.0
func initialize_spell(value: SpellCastContext) -> void:
	context = value
	collision_layer = 16 if context.spell.construct_solid else 0
	collision_mask = 0
	set_meta("optical_interface", context.spell.optical_angle)
	if context.spell.construct_solid:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(150, 16)
		shape.shape = rect
		add_child(shape)
	add_to_group("spell_construct")
func _physics_process(delta: float) -> void:
	if context == null or not context.can_execute() or not SpellExecutor.is_authoritative(context.caster): queue_free(); return
	elapsed += delta
	if elapsed >= context.spell.area_duration: queue_free(); return
	if context.spell.construct_follow: global_position = context.caster.global_position
	for node in get_tree().get_nodes_in_group("spell_projectile"):
		var p := node as MagicProjectile
		if p._finished or p.is_queued_for_deletion() or p.cast_context.source_team == context.source_team: continue
		if global_position.distance_to(p.global_position) < context.spell.aoe_spell_radius:
			if context.spell.construct_reflect: p.redirect(context, -p.direction)
			else: p._finished = true; p.queue_free()
	queue_redraw()
func _draw() -> void:
	if context == null: return
	var c := context.spell.spell_colour
	if context.spell.construct_solid:
		draw_rect(Rect2(-75, -8, 150, 16), Color(c, 0.6))
	else:
		draw_arc(Vector2.ZERO, context.spell.aoe_spell_radius, elapsed * 3, elapsed * 3 + TAU * 0.85, 48, c, 4)
	draw_line(Vector2(-30, -18), Vector2(-30 + 60 * (1 - elapsed / context.spell.area_duration), -18), c, 3)
