class_name DestructibleInteractionReceiver extends InteractionReceiver
## Existing successful impulse effects may fracture authored materials, never by spell name.
func receive_spell(context: SpellCastContext, effect: SpellEffectDefinition) -> void:
	super.receive_spell(context, effect)
	var component := get_parent().get_node("DestructibleComponent") as DestructibleComponent
	var material := component.config.material
	if material == null or material.minimum_break_force <= 0: return
	var force: float = effect.force if effect is KnockbackEffect else effect.strength if effect is VectorEffect else 0.0
	if force < material.minimum_break_force: return
	var damage := EnvironmentalDamage.from_spell(context)
	damage.kind = EnvironmentalDamage.Kind.PRESSURE
	component.apply_damage((force - material.minimum_break_force + 1.0) * (1.0 - material.knockback_resistance), damage)
