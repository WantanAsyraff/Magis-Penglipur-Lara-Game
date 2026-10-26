class_name ConditionalEffect extends SpellEffectDefinition
@export var required_status: String = "slow"
@export var children: Array[SpellEffectDefinition] = []
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if not h.get_active_effects().has(required_status):
		return false
	return SpellExecutor.execute_effects(context, target, children)
