class_name ReplayEffect extends SpellEffectDefinition
func execute(context: SpellCastContext, target: Node2D) -> bool:
	if context.state.get("echo", false): return false
	for node in target.get_children():
		if node is SpellCastingComponent and node.previous_spell != null:
			var spell: SpellData = node.previous_spell
			var copy := SpellCastContext.new(context.caster, spell)
			copy.direction = context.direction
			copy.source_position = context.source_position
			copy.targets = node.previous_targets.duplicate()
			copy.state.echo = true
			copy.modifiers.scale = 0.5
			copy.remaining_effect_budget = 64
			if spell.delivery == SpellData.Delivery.DIRECT_TARGET and (copy.targets.is_empty() or not is_instance_valid(copy.targets[0]) or copy.targets[0].global_position.distance_to(target.global_position) > spell.target_range): return false
			return SpellDelivery.dispatch(copy)
	return false
