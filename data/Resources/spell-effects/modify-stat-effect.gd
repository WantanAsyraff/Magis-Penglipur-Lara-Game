class_name ModifyStatEffect extends SpellEffectDefinition
@export_enum("speed", "damage", "mana_regen", "defense", "cast_speed", "dash_charges") var stat: String = "speed"
@export var amount: float = 0.0
@export var duration: float = 1.0
@export var stacking: ActiveEffectManager.StackPolicy = ActiveEffectManager.StackPolicy.REFRESH
@export_range(1, 32) var max_stacks: int = 1
@export var on_hit_proc_id: String = ""
func validate() -> PackedStringArray:
	if stat not in ["speed", "damage", "mana_regen", "defense", "cast_speed", "dash_charges"] or not is_finite(amount) or not is_finite(duration) or duration <= 0 or max_stacks < 1 or max_stacks > 32:
		return PackedStringArray(["Invalid stat buff"])
	return PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	return h.effects.apply("buff_" + stat, duration, {"amount": amount, "proc": on_hit_proc_id}, str(context.cast_id), stacking, max_stacks, true)
