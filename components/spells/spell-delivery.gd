class_name SpellDelivery extends RefCounted
const PLAYER_PROJECTILE = "res://components/projectiles/player-magis-projectile.tscn"
const ENEMY_PROJECTILE = "res://components/projectiles/enemy-magis-projectile.tscn"

static func dispatch(context: SpellCastContext) -> bool:
	if not context.can_execute() or not SpellExecutor.is_authoritative(context.caster):
		return false
	var spell := context.spell
	var actor := context.caster
	match LegacySpellAdapter.delivery_for(spell):
		SpellData.Delivery.SELF:
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
			actor.get_parent().add_child(area)
			area.global_position = context.source_position
			return true
		SpellData.Delivery.SUMMON:
			if spell.summon_scene == null:
				return false
			var spawned := spell.summon_scene.instantiate()
			if not spawned is Node2D:
				spawned.free()
				return false
			var entity := spawned as Node2D
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
				actor.get_parent().add_child(inst)
				inst.global_position = context.source_position
				inst.start()
			return true
	return false

static func apply_area(context: SpellCastContext, position: Vector2, beam: bool = false) -> bool:
	var radius := context.spell.decast_radius if context.spell.spell_category == SpellData.SpellCategory.DECAST else context.spell.aoe_spell_radius
	var found := false
	for node in context.caster.get_tree().get_nodes_in_group("hitbox"):
		var target := node.get_parent() as Node2D
		if target == null or target == context.caster:
			continue
		var offset := target.global_position - position
		var in_shape := offset.length() <= radius
		if beam:
			var projection := offset.dot(context.direction)
			in_shape = projection >= 0 and projection <= context.spell.target_range and absf(offset.cross(context.direction)) <= context.spell.beam_width / 2
		if in_shape and can_target(context, target):
			found = SpellExecutor.new().execute(context, target) or found
	return found

static func can_target(context: SpellCastContext, target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	var team: StringName = target.get_meta("spell_team", &"player" if target.is_in_group("player") else &"enemy")
	var ally := team == context.source_team
	if context.spell.spell_category == SpellData.SpellCategory.DECAST:
		return (ally and context.spell.purge_debuffs) or (not ally and context.spell.purge_enemy_buffs)
	match context.spell.targeting:
		SpellData.Targeting.ALLIES: return ally
		SpellData.Targeting.ANY: return true
	return not ally
