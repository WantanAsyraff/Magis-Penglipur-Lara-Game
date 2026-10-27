extends Player
# Training access is instance-local; never add demo spells to campaign progression.
@export var training_spells: Array[SpellData] = []

func can_cast_spell(spell: SpellData) -> bool:
	return is_multiplayer_authority() and spell in training_spells and Player_Global_Data.is_spell_equipped(spell)
