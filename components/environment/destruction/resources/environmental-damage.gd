class_name EnvironmentalDamage extends RefCounted
enum Kind { IMPACT, THERMAL, ELECTRICAL, PRESSURE, SONIC }
var kind: Kind = Kind.IMPACT
var instigator: Node2D
var spell_context: SpellCastContext
var destruction_context: DestructionContext
static func from_spell(context: SpellCastContext) -> EnvironmentalDamage:
	var result := EnvironmentalDamage.new()
	result.instigator = context.caster
	result.spell_context = context
	if context.spell: result.kind = context.spell.environmental_damage_kind
	return result
