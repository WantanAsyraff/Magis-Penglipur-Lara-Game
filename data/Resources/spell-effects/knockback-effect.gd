class_name KnockbackEffect extends SpellEffectDefinition
@export var force: float = 0.0
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid force"]) if not is_finite(force) or force < 0 else PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if h.receives_knockback:
		h._apply_knockback(context.direction, force)
	return true
