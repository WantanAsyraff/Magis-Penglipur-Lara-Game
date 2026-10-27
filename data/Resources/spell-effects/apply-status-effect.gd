class_name ApplyStatusEffect extends SpellEffectDefinition
@export var status: String = "stun"
@export var duration: float = 1.0
@export var magnitude: float = 0.0
@export var tick_interval: float = 1.0
@export var stacking: ActiveEffectManager.StackPolicy = ActiveEffectManager.StackPolicy.REFRESH
@export_range(1, 32) var max_stacks: int = 1

func validate() -> PackedStringArray:
	if status.is_empty() or not is_finite(duration) or duration <= 0 or not is_finite(magnitude) or magnitude < 0 or not is_finite(tick_interval) or tick_interval < 0.05 or max_stacks < 1 or max_stacks > 32:
		return PackedStringArray(["Invalid status configuration"])
	return PackedStringArray()

func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if not h.receives_status_effects or h.is_invincible() or (status == "mana_drain" and not h.has_mana):
		return false
	return h.effects.apply(status, duration, {"amount": magnitude, "factor": clampf(magnitude, 0, 1), "interval": tick_interval}, str(context.cast_id), stacking, max_stacks)
