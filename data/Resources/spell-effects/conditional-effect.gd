class_name ConditionalEffect extends SpellEffectDefinition
@export var required_status: String = "slow"
@export var children: Array[SpellEffectDefinition] = []
@export var minimum_stacks: int = 1
@export var consume: bool = false
@export var capability: StringName = &""
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if capability != &"" and not target.has_meta(capability):
		return false
	var count := 0
	for entry in h.effects.entries:
		if entry.key == required_status: count += 1
	if count < minimum_stacks:
		return false
	if consume: h.remove_effect(required_status)
	return SpellExecutor.execute_effects(context, target, children)
