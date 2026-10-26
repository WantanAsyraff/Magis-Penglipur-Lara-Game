class_name SpellValidator extends RefCounted

static func validate(spell: SpellData) -> PackedStringArray:
	var errors := PackedStringArray()
	if spell == null:
		return PackedStringArray(["Missing spell resource"])
	if spell.spell_id.strip_edges().is_empty():
		errors.append("Empty spell ID")
	for property in ["upfront_cost", "mana_per_second", "cast_time", "channel_duration", "cooldown", "recovery_time", "projectile_damage", "projectile_speed", "projectile_range", "projectile_size", "aoe_spell_radius", "target_range", "decast_radius", "area_duration", "beam_width"]:
		var value := float(spell.get(property))
		if not is_finite(value) or value < 0:
			errors.append("Invalid nonnegative property: " + property)
	if spell.projectile_count < 1 or spell.projectile_count > 128:
		errors.append("Projectile count must be 1..128")
	if spell.is_channelled and spell.channel_duration <= 0:
		errors.append("Channel duration must be positive")
	if spell.buff_type < 0 or spell.buff_type >= SpellData.BuffType.size():
		errors.append("Invalid buff type")
		return errors
	var delivery := LegacySpellAdapter.delivery_for(spell)
	if delivery == SpellData.Delivery.PROJECTILE:
		if spell.projectile_speed <= 0 or spell.projectile_range <= 0 or spell.projectile_size <= 0:
			errors.append("Projectile requires positive speed, range and size")
		if spell.spell_scene:
			var inst := spell.spell_scene.instantiate()
			if not inst is SpellEffect:
				errors.append("Projectile scene must extend SpellEffect")
			inst.free()
	if delivery in [SpellData.Delivery.AREA_BURST, SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.TRAP] and maxf(spell.aoe_spell_radius, spell.decast_radius) <= 0:
		errors.append("Area delivery requires a radius")
	if delivery in [SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.TRAP, SpellData.Delivery.BEAM] and (spell.area_duration <= 0 or not is_finite(spell.area_tick_interval) or spell.area_tick_interval < 0.05):
		errors.append("Invalid persistent area duration or interval")
	if delivery == SpellData.Delivery.SUMMON and spell.summon_scene == null:
		errors.append("Summon requires a scene")
	if delivery < SpellData.Delivery.PROJECTILE or delivery > SpellData.Delivery.SUMMON:
		errors.append("Unsupported delivery")
	for direction in spell.spell_incantation:
		if direction not in ["up", "down", "left", "right"]:
			errors.append("Invalid incantation direction")
	for field in spell.academic_fields:
		if field == null or field.field_id == &"":
			errors.append("Missing academic field reference or ID")
	var definitions := LegacySpellAdapter.effects_for(spell)
	if definitions.is_empty() and delivery != SpellData.Delivery.SUMMON:
		errors.append("Spell has no effect payload")
	_validate_effects(definitions, errors, [], 0)
	return errors

static func _validate_effects(definitions: Array[SpellEffectDefinition], errors: PackedStringArray, ancestors: Array, depth: int) -> void:
	if depth > 8:
		errors.append("Effect nesting exceeds 8")
		return
	for effect in definitions:
		if effect == null:
			errors.append("Missing effect resource")
			continue
		if effect in ancestors:
			errors.append("Circular effect reference")
			continue
		errors.append_array(effect.validate())
		if effect is ConditionalEffect:
			_validate_effects(effect.children, errors, ancestors + [effect], depth + 1)
