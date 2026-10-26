class_name LegacySpellAdapter extends RefCounted
# Convert old flags into per-cast effect definitions without changing shared resources.
static func effects_for(spell: SpellData) -> Array[SpellEffectDefinition]:
	if not spell.effects.is_empty():
		return spell.effects
	var result: Array[SpellEffectDefinition] = []
	match spell.spell_category:
		SpellData.SpellCategory.HEALING:
			var heal := HealEffect.new()
			heal.amount = spell.hot_tick_heal if spell.heal_over_time else spell.heal_amount
			heal.duration = spell.hot_duration if spell.heal_over_time else 0.0
			heal.tick_interval = spell.hot_tick_interval
			result.append(heal)
		SpellData.SpellCategory.BUFF:
			var buff := ModifyStatEffect.new()
			buff.stat = ["speed", "damage", "mana_regen", "defense", "cast_speed", "dash_charges"][spell.buff_type]
			buff.amount = spell.buff_magnitude
			buff.duration = spell.buff_duration
			buff.stacking = ActiveEffectManager.StackPolicy.STACK if spell.is_stackable else ActiveEffectManager.StackPolicy.REFRESH
			buff.max_stacks = spell.max_stacks
			buff.on_hit_proc_id = spell.on_hit_proc_id
			result.append(buff)
		SpellData.SpellCategory.DECAST:
			var dispel := RemoveStatusEffect.new()
			dispel.respect_teams = true
			dispel.remove_buffs = spell.purge_enemy_buffs
			dispel.remove_debuffs = spell.purge_debuffs or spell.decast_mode == SpellData.DecastMode.DISPEL_SELF
			result.append(dispel)
		_:
			if spell.projectile_damage > 0:
				var damage := DamageEffect.new()
				damage.amount = spell.projectile_damage
				result.append(damage)
			if spell.knockback_force > 0:
				var knockback := KnockbackEffect.new()
				knockback.force = spell.knockback_force
				result.append(knockback)
			for key in ["stun", "slow", "dot", "mana_drain", "silence"]:
				var enabled: bool = {"stun": spell.stunnable, "slow": spell.applies_slow, "dot": spell.dot, "mana_drain": spell.applies_mana_drain, "silence": spell.applies_silence}[key]
				if not enabled:
					continue
				var status := ApplyStatusEffect.new()
				status.status = key
				status.duration = {"stun": spell.stun_dur, "slow": spell.slow_duration, "dot": spell.dot_duration, "mana_drain": spell.mana_drain_duration, "silence": spell.silence_duration}[key]
				status.magnitude = {"stun": 0.0, "slow": spell.slow_factor, "dot": spell.dot_damage, "mana_drain": spell.mana_drain_amount, "silence": 0.0}[key]
				status.tick_interval = spell.dot_interval if key == "dot" else 1.0
				result.append(status)
	return result

static func delivery_for(spell: SpellData) -> int:
	if spell.delivery != SpellData.Delivery.LEGACY:
		return spell.delivery
	if spell.is_self_cast or spell.spell_category in [SpellData.SpellCategory.HEALING, SpellData.SpellCategory.BUFF]:
		return SpellData.Delivery.SELF
	if spell.spell_category == SpellData.SpellCategory.DECAST:
		if spell.decast_mode == SpellData.DecastMode.DISPEL_SELF:
			return SpellData.Delivery.SELF
		if spell.decast_mode == SpellData.DecastMode.AOE_PULSE:
			return SpellData.Delivery.AREA_BURST
	if spell.spell_category == SpellData.SpellCategory.AOE:
		return SpellData.Delivery.AREA_BURST
	return SpellData.Delivery.PROJECTILE
