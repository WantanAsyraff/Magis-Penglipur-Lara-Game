class_name SpellCategoryFilter extends OptionButton
## Overlapping categories reflect both authored classification and effective payloads.
## Older physics resources omit classification, so delivery/effects supply useful tags.
enum Category { ALL, RANGED, MELEE, BUFF, SUPPORT, DEFENSE, AREA, CONTROL, MOVEMENT }
const LABELS := ["All spells", "Ranged", "Melee", "Buffs", "Support / healing", "Defense", "Area", "Control", "Movement"]

func _ready() -> void:
	for i in LABELS.size(): add_item(LABELS[i], i)
	tooltip_text = "Filter spells by type. A spell can belong to several categories."

func matches(spell: SpellData) -> bool:
	return matches_category(spell, get_selected_id())

static func matches_category(spell: SpellData, category: int) -> bool:
	if spell == null: return false
	if category == Category.ALL: return true
	var delivery := LegacySpellAdapter.delivery_for(spell)
	var effects := _flatten(LegacySpellAdapter.effects_for(spell), [])
	match category:
		Category.RANGED:
			return spell.spell_manifest == SpellData.SpellManifest.RANGED or delivery in [SpellData.Delivery.PROJECTILE, SpellData.Delivery.BEAM]
		Category.MELEE:
			return spell.spell_manifest == SpellData.SpellManifest.MELEE and delivery == SpellData.Delivery.DIRECT_TARGET and spell.spell_type == SpellData.SpellType.OFFENSIVE and spell.target_range <= 200
		Category.BUFF:
			if spell.spell_category == SpellData.SpellCategory.BUFF or spell.spell_type == SpellData.SpellType.ENHANCEMENT: return true
			for effect in effects:
				if effect is ModifyStatEffect or effect is TriggerEffect: return true
		Category.SUPPORT:
			if spell.spell_type in [SpellData.SpellType.SUPPORTIVE, SpellData.SpellType.HEALING, SpellData.SpellType.RECOVERY] or spell.spell_category in [SpellData.SpellCategory.HEALING, SpellData.SpellCategory.DECAST]: return true
			for effect in effects:
				if effect is HealEffect or effect is ReplayEffect: return true
				if effect is RemoveStatusEffect and (delivery == SpellData.Delivery.SELF or spell.targeting != SpellData.Targeting.ENEMIES): return true
		Category.DEFENSE:
			return spell.spell_type == SpellData.SpellType.DEFENSIVE or spell.spell_manifest == SpellData.SpellManifest.PROTECTIVE or delivery == SpellData.Delivery.SUMMON
		Category.AREA:
			return spell.spell_type == SpellData.SpellType.AOE or delivery in [SpellData.Delivery.AREA_BURST, SpellData.Delivery.PERSISTENT_AREA, SpellData.Delivery.TRAP]
		Category.CONTROL:
			if spell.spell_type == SpellData.SpellType.IMPAIRMENT or spell.spell_manifest == SpellData.SpellManifest.CONTROL: return true
			for effect in effects:
				if effect is ApplyStatusEffect or effect is KnockbackEffect or effect is InterruptEffect or effect is ProjectileFieldEffect or (effect is VectorEffect and delivery != SpellData.Delivery.SELF): return true
		Category.MOVEMENT:
			if spell.spell_type == SpellData.SpellType.MOVEMENT: return true
			for effect in effects:
				if effect is TeleportEffect or (effect is VectorEffect and delivery == SpellData.Delivery.SELF): return true
	return false

static func _flatten(definitions: Array[SpellEffectDefinition], visited: Array) -> Array[SpellEffectDefinition]:
	var result: Array[SpellEffectDefinition] = []
	for effect in definitions:
		if effect == null or effect in visited or visited.size() >= 128: continue
		visited.append(effect)
		result.append(effect)
		if effect is ConditionalEffect or effect is TriggerEffect or effect is SpawnEntityEffect:
			result.append_array(_flatten(effect.children, visited))
	return result
