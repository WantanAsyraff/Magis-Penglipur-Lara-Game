class_name SpellDelivery extends RefCounted
const PLAYER_PROJECTILE = "res://components/projectiles/player-magis-projectile.tscn"
const ENEMY_PROJECTILE = "res://components/projectiles/enemy-magis-projectile.tscn"

static func dispatch(context: SpellCastContext) -> bool:
	if not context.can_execute() or not SpellExecutor.is_authoritative(context.caster):
		return false
	var spell := context.spell
	var actor := context.caster
	# Per-caster cap bounds persistent nodes, even across different spell IDs.
	if LegacySpellAdapter.delivery_for(spell) in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.TRAP, SpellData.Delivery.BEAM, SpellData.Delivery.SUMMON]:
		var active := 0
		for child in actor.get_parent().get_children():
			if (child is SpellAreaDelivery or child is SpellConstruct) and child.context.caster == actor and not child.is_queued_for_deletion(): active += 1
		if active >= 12: return false

	match LegacySpellAdapter.delivery_for(spell):
		SpellData.Delivery.SELF:
			SpellFeedback.flash(actor, spell.spell_colour)
			var applied := SpellExecutor.new().execute(context, actor)
			if spell.aoe_spell_radius > 0:
				applied = apply_area(context, actor.global_position) or applied
			return applied
		SpellData.Delivery.DIRECT_TARGET:
			return not context.targets.is_empty() and can_target(context, context.targets[0]) and SpellExecutor.new().execute(context, context.targets[0])
		SpellData.Delivery.AREA_BURST:
			apply_area(context, context.source_position)
			return true
		SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.BEAM, SpellData.Delivery.TRAP:
			var area := SpellAreaDelivery.new()
			area.context = context
			CombatLifecycle.own(area, actor)
			actor.get_parent().add_child(area)
			area.global_position = context.source_position
			return true
		SpellData.Delivery.SUMMON:
			if spell.summon_scene == null:
				return false
			if spell.construct_solid:
				var query := PhysicsShapeQueryParameters2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(150, 16)
				query.shape = rect
				query.transform = Transform2D(0, context.source_position)
				query.collision_mask = 16
				if not actor.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): return false
			var spawned := spell.summon_scene.instantiate()
			if not spawned is Node2D:
				spawned.free()
				return false
			var entity := spawned as Node2D
			CombatLifecycle.own(entity, actor)
			actor.get_parent().add_child(entity)
			entity.global_position = context.source_position
			if not spell.effects.is_empty():
				SpellExecutor.new().execute(context, entity)
			if entity.has_method("initialize_spell"):
				entity.initialize_spell(context)
			return true
		SpellData.Delivery.PROJECTILE:
			var scene := spell.spell_scene
			if scene == null:
				scene = load(PLAYER_PROJECTILE if context.source_team == &"player" else ENEMY_PROJECTILE) as PackedScene
			for i in spell.projectile_count:
				var spawned := scene.instantiate()
				if not spawned is SpellEffect:
					spawned.free()
					return false
				var inst := spawned as SpellEffect
				inst.spell_data = spell
				inst.source = actor
				inst.cast_context = context
				var angle := 0.0 if spell.projectile_count == 1 else deg_to_rad(-spell.projectile_spread / 2 + spell.projectile_spread * i / (spell.projectile_count - 1))
				inst.direction = context.direction.rotated(angle)
				CombatLifecycle.own(inst, actor)
				actor.get_parent().add_child(inst)
				inst.global_position = context.source_position
				inst.collision_mask = CombatFactions.projectile_mask(context.source_team)
				inst.start()
			return true
	return false

static func apply_area(context: SpellCastContext, position: Vector2, beam: bool = false) -> bool:
	var radius := context.spell.decast_radius if context.spell.spell_category == SpellData.SpellCategory.DECAST else context.spell.aoe_spell_radius
	var found := false
	if context.spell.affects_projectiles:
		for effect in context.spell.effects:
			if effect is ProjectileFieldEffect:
				found = SpellExecutor.execute_effects(context, context.caster, [effect]) or found

	for node in context.caster.get_tree().get_nodes_in_group("hitbox"):
		var target := node.get_parent() as Node2D
		if target == null: continue
		if target == context.caster and (context.spell.targeting == SpellData.Targeting.ENEMIES or LegacySpellAdapter.delivery_for(context.spell) == SpellData.Delivery.SELF): continue
		var offset := target.global_position - position
		var in_shape := target_distance(position, target) <= radius
		if beam:
			in_shape = beam_hits(target, position, position + context.direction * context.spell.target_range, context.spell.beam_width)

		if in_shape and can_target(context, target):
			var previous_direction := context.direction
			if context.spell.delivery == SpellData.Delivery.AREA_BURST and offset != Vector2.ZERO: context.direction = offset.normalized()
			found = SpellExecutor.new().execute(context, target) or found
			context.direction = previous_direction
	return found

static func can_target(context: SpellCastContext, target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	var relation := CombatFactions.relation(context.caster, target)
	if target.get_meta("combat_dead", false) or target.is_queued_for_deletion(): return false
	var ally := relation > 0
	if context.spell.spell_category == SpellData.SpellCategory.DECAST:
		return (ally and context.spell.purge_debuffs) or (relation < 0 and context.spell.purge_enemy_buffs)
	match context.spell.targeting:
		SpellData.Targeting.ALLIES: return ally
		SpellData.Targeting.ANY: return true
	return relation < 0

static func pick_target(context: SpellCastContext) -> Node2D:
	var best: Node2D
	var score := INF
	for h in context.caster.get_tree().get_nodes_in_group("hitbox"):
		var target := h.get_parent() as Node2D
		if target == null or target == context.caster or not can_target(context, target): continue
		var offset := target.global_position - context.caster.global_position
		if offset.length() > context.spell.target_range or offset.normalized().dot(context.direction) < 0.35: continue
		var candidate := offset.length() + absf(offset.cross(context.direction)) * 2
		if candidate < score: best = target; score = candidate
	return best

## Physics body bounds, in world coordinates. Areas, beams and pushes must hit the body,
## including scaled actors, rather than requiring its pivot to be inside the spell.
static func target_bounds(target: Node2D) -> Rect2:
	var bounds := Rect2(target.global_position, Vector2.ZERO)
	var found := false
	for child in target.get_children():
		if child is CollisionShape2D and child.shape != null and not child.disabled:
			var rect: Rect2 = child.global_transform * child.shape.get_rect()
			bounds = bounds.merge(rect) if found else rect
			found = true
	return bounds

static func target_distance(point: Vector2, target: Node2D) -> float:
	var rect := target_bounds(target)
	return point.distance_to(point.clamp(rect.position, rect.end))

static func beam_hits(target: Node2D, start: Vector2, end: Vector2, width: float) -> bool:
	var rect := target_bounds(target).grow(width / 2.0)
	if rect.has_point(start) or rect.has_point(end): return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(start, end, corners[i], corners[(i+1)%4]) != null: return true
	return false
