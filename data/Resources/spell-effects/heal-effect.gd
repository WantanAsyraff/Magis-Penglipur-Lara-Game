class_name HealEffect extends SpellEffectDefinition
@export var amount: float = 0.0
@export var duration: float = 0.0
@export var tick_interval: float = 1.0

func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid healing amount, duration or interval"]) if not is_finite(amount) or amount < 0 or not is_finite(duration) or duration < 0 or not is_finite(tick_interval) or tick_interval < 0.05 else PackedStringArray()

func execute(context: SpellCastContext, target: Node2D) -> bool:
	var hitbox: HitboxComponent = target.get_node("HitboxComponent")
	if duration > 0:
		hitbox.effects.apply("hot", duration, {"amount": amount * float(context.modifiers.get("scale", 1.0)), "interval": tick_interval}, str(context.cast_id), ActiveEffectManager.StackPolicy.STACK, 32, true)
	else:
		hitbox.healed.emit(amount * float(context.modifiers.get("scale", 1.0)))
	return true
