extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")
const MAX_EQUIPPED_SPELLS = 8
const CARD_MIN_WIDTH = 224
const CARD_GAP = 12

@onready var vbox: VBoxContainer = %LearnedSpells
@onready var spellEquip: GridContainer = %SpellEquipmentContainer
var _refresh_pending := false

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_schedule_refresh)
	%LoadoutScroll.resized.connect(_update_columns)
	%CategoryFilter.item_selected.connect(func(_index): _populate_both())
	_populate_both()

func _schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	_populate_both.call_deferred()

func _populate_both() -> void:
	_refresh_pending = false
	_clear_cards(vbox)
	_clear_cards(spellEquip)
	for spell in Player_Global_Data.learned_spells:
		if not Player_Global_Data.is_spell_equipped(spell) and %CategoryFilter.matches(spell):
			_add_card(vbox, spell, false, _on_learned_spell_selected)
	for spell in Player_Global_Data.equipped_spells:
		_add_card(spellEquip, spell, true, _on_equipped_spell_selected)
	%LearnedCountLabel.text = "%d available" % vbox.get_child_count()
	%EquippedCountLabel.text = "%d / %d slots used" % [spellEquip.get_child_count(), MAX_EQUIPPED_SPELLS]
	%LearnedEmptyLabel.text = "All learned spells are equipped." if not Player_Global_Data.learned_spells.is_empty() else "Learn a spell to add it to your loadout."
	if %CategoryFilter.get_selected_id() != SpellCategoryFilter.Category.ALL:
		%LearnedEmptyLabel.text = "No available spells of this type. Choose another type or All spells."
	%LearnedEmptyLabel.visible = vbox.get_child_count() == 0
	%EquippedEmptyLabel.text = "Your loadout is empty. Choose a spell from the left."
	%EquippedEmptyLabel.visible = spellEquip.get_child_count() == 0
	_update_columns()

func _clear_cards(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _add_card(container: Container, spell: SpellData, equipped: bool, callback: Callable) -> void:
	var slot: SpellSlot = SPELL_SLOT.instantiate()
	container.add_child(slot)
	slot.set_spell(spell, equipped)
	slot.spell_selected.connect(callback)

func _update_columns() -> void:
	# Allow room for the vertical scrollbar before selecting the second column.
	var available: float = %LoadoutScroll.size.x - %LoadoutScroll.get_v_scroll_bar().get_combined_minimum_size().x
	spellEquip.columns = 2 if available >= CARD_MIN_WIDTH * 2 + CARD_GAP else 1

func _on_learned_spell_selected(spell: SpellData) -> void:
	Player_Global_Data.selected_spell = spell
	if Player_Global_Data.equipped_spells.size() >= MAX_EQUIPPED_SPELLS:
		%FeedbackLabel.text = "All 8 slots are full. Remove an equipped spell to make room."
		return
	Player_Global_Data.equip_spell(spell)
	%FeedbackLabel.text = spell.spell_name + " equipped."

func _on_equipped_spell_selected(spell: SpellData) -> void:
	Player_Global_Data.selected_spell = spell
	Player_Global_Data.unequip_spell(spell)
	%FeedbackLabel.text = spell.spell_name + " removed from your loadout."

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/spell-equipment/spellku-main-menu.tscn")
