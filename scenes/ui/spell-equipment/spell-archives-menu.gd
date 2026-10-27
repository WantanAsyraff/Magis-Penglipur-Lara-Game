class_name SpellArchivesMenu
extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_populate_spell_list)
	_populate_spell_list()

func _populate_spell_list() -> void:
	for child in %LearnedSpells.get_children():
		%LearnedSpells.remove_child(child)
		child.queue_free()
	for spell in Player_Global_Data.learned_spells:
		var slot = SPELL_SLOT.instantiate()
		%LearnedSpells.add_child(slot)
		slot.set_spell(spell, Player_Global_Data.is_spell_equipped(spell))
		slot.spell_selected.connect(_on_spell_selected)
	var selected := Player_Global_Data.selected_spell
	if not Player_Global_Data.learned_spells.has(selected):
		selected = Player_Global_Data.learned_spells[0] if not Player_Global_Data.learned_spells.is_empty() else null
	if selected:
		_on_spell_selected(selected)
	else:
		Player_Global_Data.selected_spell = null
		%TextureRect.texture = null
		%SpellNameLabel.text = "No learned spells"
		%SpellFlavourLabel.text = "Learn a spell to view its incantation, effects and theory."
		%SpellMoveLabel.text = ""
		%SpellTheoryLabel.text = ""
		%CastersNotesLabel.text = ""

func _on_spell_selected(spell: SpellData) -> void:
	Player_Global_Data.selected_spell = spell
	_populate(spell)

func _populate(spell: SpellData) -> void:
	%TextureRect.texture = spell.spell_icon
	%SpellNameLabel.text = spell.spell_name
	%SpellFlavourLabel.text = spell.spell_flavour_text
	%SpellMoveLabel.text = _build_move_desc(spell)
	%SpellTheoryLabel.text = spell.theory_desc
	%CastersNotesLabel.text = _build_stats(spell)

func _build_move_desc(spell: SpellData) -> String:
	return SpellDescription.casting(spell)

func _build_stats(spell: SpellData) -> String:
	return SpellDescription.stats(spell)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/spell-equipment/spellku-main-menu.tscn")
