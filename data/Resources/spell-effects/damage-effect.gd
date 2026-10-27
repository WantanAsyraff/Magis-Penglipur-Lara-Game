class_name DamageEffect extends SpellEffectDefinition
@export var amount: float = 0.0

func validate() -> PackedStringArray:
	return PackedStringArray(["Damage must be finite and nonnegative"]) if not is_finite(amount) or amount < 0.0 else PackedStringArray()

func accepts(target: Node2D) -> bool:
	return super.accepts(target) or (is_instance_valid(target) and target.has_method("take_damage"))

func execute(context: SpellCastContext, target: Node2D) -> bool:
	var hitbox := target.get_node_or_null("HitboxComponent") as HitboxComponent
	var bonus: float = context.modifiers.get("damage", 0.0)
	if hitbox:
		hitbox._apply_damage(maxf(amount * float(context.modifiers.get("scale", 1.0)) + bonus, 0.0))
	else:
		target.take_damage(int(maxf(amount * float(context.modifiers.get("scale", 1.0)) + bonus, 0.0)))
	SpellFeedback.flash(target, context.spell.spell_colour)
	return true
