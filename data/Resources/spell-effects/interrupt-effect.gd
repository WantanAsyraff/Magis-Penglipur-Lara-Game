class_name InterruptEffect extends SpellEffectDefinition
func execute(_context: SpellCastContext, target: Node2D) -> bool:
	for child in target.get_children():
		if child is SpellCastingComponent: child.cancel("Interrupted by pressure wave")
	return true
