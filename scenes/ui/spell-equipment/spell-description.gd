class_name SpellDescription extends RefCounted
## Read the same effective payload as casting; legacy fields are fallback data only.
static func casting(spell: SpellData) -> String:
	var delivery := LegacySpellAdapter.delivery_for(spell)
	var lines: Array[String] = [
		"Delivery: " + _enum_label(SpellData.Delivery.keys(), delivery),
		"Targets: " + ("Self" if delivery == SpellData.Delivery.SELF else _enum_label(SpellData.Targeting.keys(), spell.targeting)),
		"Archetype: " + spell.magis_archetype,
		"Comprehension: " + spell.magis_comprehension,
		"Incantation: " + (" → ".join(spell.spell_incantation) if not spell.spell_incantation.is_empty() else "None")
	]
	return "\n".join(lines)

static func stats(spell: SpellData) -> String:
	var delivery := LegacySpellAdapter.delivery_for(spell)
	var lines: Array[String] = ["Mana Cost: %d MP" % spell.upfront_cost,
		"Cast Time: %s s" % _number(spell.cast_time), "Cooldown: %s s" % _number(spell.cooldown)]
	if spell.is_channelled:
		lines.append("Channel: %s s at %s MP/s" % [_number(spell.channel_duration), _number(spell.mana_per_second)])
		lines.append("Channel effects: " + ("During channel" if spell.live_channel else "On completion"))
	if spell.recovery_time > 0: lines.append("Recovery: %s s" % _number(spell.recovery_time))
	if delivery == SpellData.Delivery.PROJECTILE:
		lines.append("Projectile Speed: %s px/s" % _number(spell.projectile_speed))
		lines.append("Projectile Range: %s px" % _number(spell.projectile_range))
		lines.append("Projectiles: %d" % spell.projectile_count)
		if spell.piercing: lines.append("Pierces targets")
	if delivery in [SpellData.Delivery.DIRECT_TARGET, SpellData.Delivery.BEAM]:
		lines.append("Target Range: %s px" % _number(spell.target_range))
	if delivery == SpellData.Delivery.BEAM:
		lines.append("Beam Width: %s px; Output Paths: %d" % [_number(spell.beam_width), spell.beam_angles.size()])
	var radius := spell.decast_radius if spell.spell_category == SpellData.SpellCategory.DECAST else spell.aoe_spell_radius
	if radius > 0: lines.append("Area Radius: %s px" % _number(radius))
	if delivery in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.BEAM, SpellData.Delivery.TRAP, SpellData.Delivery.SUMMON]:
		lines.append("Lifetime: %s s" % _number(spell.area_duration))
	if delivery in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.BEAM, SpellData.Delivery.TRAP]:
		lines.append("Effect Interval: %s s" % _number(spell.area_tick_interval))
	if delivery == SpellData.Delivery.TRAP: lines.append("Triggers once when an eligible target enters")
	if delivery == SpellData.Delivery.SUMMON:
		if spell.construct_solid: lines.append("Creates a solid platform / surface")
		if spell.construct_follow: lines.append("Follows the caster")
		if spell.construct_reflect: lines.append("Reflects hostile projectiles and redirects beams")
		elif spell.aoe_spell_radius > 0: lines.append("Intercepts hostile projectiles")
	var effects := LegacySpellAdapter.effects_for(spell)
	if not effects.is_empty():
		lines.append("")
		lines.append("Effects:" + (" (each tick)" if delivery in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.BEAM] else ""))
		lines.append_array(_effects(effects))
	return "\n".join(lines)

static func _effects(definitions: Array[SpellEffectDefinition], indent: String = "", ancestors: Array = [], depth: int = 0) -> Array[String]:
	var lines: Array[String] = []
	if depth > 8: return [indent + "Further effects omitted (nesting limit)"]
	for effect in definitions.slice(0, 256):
		if effect == null:
			lines.append(indent + "Unavailable effect")
			continue
		if effect in ancestors:
			lines.append(indent + "Circular effect reference")
			continue
		var text := ""
		var children: Array[SpellEffectDefinition] = []
		if effect is DamageEffect:
			text = "Damage: %s" % _number(effect.amount)
		elif effect is HealEffect:
			text = "Healing: %s HP" % _number(effect.amount)
			if effect.duration > 0: text += " every %s s for %s s" % [_number(effect.tick_interval), _number(effect.duration)]
		elif effect is KnockbackEffect:
			text = "Knockback: %s" % _number(effect.force)
		elif effect is ApplyStatusEffect:
			text = "%s for %s s" % [effect.status.capitalize(), _number(effect.duration)]
			if effect.status == "slow": text = "Slow: %s%% for %s s" % [_number(effect.magnitude * 100), _number(effect.duration)]
			elif effect.status in ["dot", "mana_drain"]: text = "%s: %s %s every %s s for %s s" % ["Damage over time" if effect.status == "dot" else "Mana drain", _number(effect.magnitude), "damage" if effect.status == "dot" else "MP", _number(effect.tick_interval), _number(effect.duration)]
			if effect.stacking == ActiveEffectManager.StackPolicy.STACK: text += " (up to %d stacks)" % effect.max_stacks
		elif effect is RemoveStatusEffect:
			var removals: Array[String] = []
			if not effect.status.is_empty(): removals.append(effect.status.capitalize())
			if effect.remove_buffs: removals.append("enemy buffs" if effect.respect_teams else "buffs")
			if effect.remove_debuffs: removals.append("allied debuffs" if effect.respect_teams else "debuffs")
			text = "Removes: " + ", ".join(removals)
		elif effect is ModifyStatEffect:
			var amount := ("+" if effect.amount >= 0 else "") + _number(effect.amount)
			if effect.stat == "cast_speed": amount = ("+" if effect.amount >= 0 else "") + _number(effect.amount * 100) + "%"
			text = "%s: %s for %s s" % [effect.stat.capitalize(), amount, _number(effect.duration)]
			if effect.stacking == ActiveEffectManager.StackPolicy.STACK: text += " (up to %d stacks)" % effect.max_stacks
		elif effect is ConditionalEffect:
			text = "If target has %s (%d+ stacks)" % [effect.required_status.capitalize(), effect.minimum_stacks]
			if effect.capability != &"": text += " and is " + String(effect.capability).capitalize()
			if effect.consume: text += "; consumes " + effect.required_status.capitalize()
			text += ":"
			children = effect.children
		elif effect is TriggerEffect:
			text = "After %d damaging hit(s) within %s s (once):" % [effect.hits, _number(effect.duration)]
			children = effect.children
		elif effect is ChainEffect:
			text = "Chain: up to %d additional targets within %s px; %s damage on first jump, 25%% less per later jump" % [effect.hops, _number(effect.radius), _number(effect.amount)]
			if not effect.preferred_status.is_empty(): text += "; prioritizes " + effect.preferred_status.capitalize()
		elif effect is VectorEffect:
			text = "%s: %s" % [["Directional impulse", "Attraction", "Rotating force", "Movement damping", "Upward lift"][effect.mode], _number(effect.strength)]
			if effect.mode == VectorEffect.Mode.DAMP: text = "Movement damping: %s%%" % _number(effect.strength * 100)
			if effect.capability != &"": text += " (" + String(effect.capability).capitalize() + " targets only)"
		elif effect is ProjectileFieldEffect:
			text = ["Reverses hostile projectiles and transfers ownership", "Curves hostile projectile trajectories", "Slows hostile projectiles to %s%% speed" % _number(effect.strength * 100), "Cancels hostile wave projectiles and areas"][effect.mode]
			text += " within %s px" % _number(effect.radius)
		elif effect is TeleportEffect:
			text = "Displacement: %s px; blocked by solid geometry" % _number(effect.distance)
		elif effect is ReplayEffect:
			text = "Replays the previous eligible spell at 50% damage / healing; cannot echo itself"
		elif effect is InterruptEffect:
			text = "Interrupts preparation and channeling"
		elif effect is SpawnEntityEffect:
			text = "Spawns a configured entity:"
			children = effect.children
		else:
			text = "Additional spell effect"
		lines.append(indent + text)
		if not children.is_empty(): lines.append_array(_effects(children, indent + "    ", ancestors + [effect], depth + 1))
	return lines

static func _number(value: float) -> String:
	var formatted := String.num(value, 2)
	return formatted.rstrip("0").trim_suffix(".") if formatted.contains(".") else formatted

static func _enum_label(keys: Array, value: int) -> String:
	return String(keys[value]).capitalize() if value >= 0 and value < keys.size() else "Unknown"
