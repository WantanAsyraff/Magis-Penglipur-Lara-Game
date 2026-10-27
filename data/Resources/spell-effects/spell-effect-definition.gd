class_name SpellEffectDefinition extends Resource

func validate() -> PackedStringArray:
	return PackedStringArray()

func accepts(target: Node2D) -> bool:
	return is_instance_valid(target) and target.get_node_or_null("HitboxComponent") != null

func execute(_context: SpellCastContext, _target: Node2D) -> bool:
	return false
