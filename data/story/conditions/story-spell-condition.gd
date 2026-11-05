class_name StorySpellCondition extends StoryCondition
@export var spell: SpellData
@export var must_be_learned := true
func validate(_registry: StoryRegistry) -> PackedStringArray:
	return PackedStringArray(["A registered spell is required"]) if spell == null or Spell_Library.get_spell_by_id(spell.spell_id) != spell else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
	return validate(context.registry).is_empty() and Player_Global_Data.has_spell(spell) == must_be_learned
