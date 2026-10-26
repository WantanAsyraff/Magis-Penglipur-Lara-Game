class_name DamageEffect extends SpellEffectDefinition
@export var amount: float = 0.0

func validate() -> PackedStringArray:
	return PackedStringArray(["Damage must be finite and nonnegative"]) if not is_finite(amount) or amount < 0.0 else PackedStringArray()

func execute(context: SpellCastContext, target: Node2D) -> bool:
	var hitbox: HitboxComponent = target.get_node("HitboxComponent")
	var bonus: float = context.modifiers.get("damage", 0.0)
	hitbox._apply_damage(maxf(amount + bonus, 0.0))
	return true
