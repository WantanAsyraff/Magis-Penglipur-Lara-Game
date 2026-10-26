class_name SpellExecutor extends RefCounted
signal effect_executed(cast_id: int, target: Node2D, effect: SpellEffectDefinition)
signal execution_failed(cast_id: int, reason: String)

static func is_authoritative(node: Node) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and (not node.multiplayer.has_multiplayer_peer() or node.multiplayer.is_server())

static func execute_effects(context: SpellCastContext, target: Node2D, definitions: Array[SpellEffectDefinition], on_success: Callable = Callable()) -> bool:
	if not context.can_execute() or not is_authoritative(context.caster) or not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	var applied := false
	context.chain_depth += 1
	for effect in definitions:
		if not context.can_execute() or not is_instance_valid(target) or target.is_queued_for_deletion():
			break
		context.remaining_effect_budget -= 1
		if effect != null and effect.validate().is_empty() and effect.accepts(target):
			if effect.execute(context, target):
				applied = true
				if on_success.is_valid() and is_instance_valid(target):
					on_success.call(context.cast_id, target, effect)
	context.chain_depth -= 1
	return applied

func execute(context: SpellCastContext, target: Node2D) -> bool:
	if context == null or context.spell == null:
		return false
	var definitions := LegacySpellAdapter.effects_for(context.spell)
	var result := execute_effects(context, target, definitions, effect_executed.emit)
	if not result:
		execution_failed.emit(context.cast_id, "No compatible effects or execution budget exhausted")
	return result
