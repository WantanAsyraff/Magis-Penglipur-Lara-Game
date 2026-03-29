extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")
const MAX_EQUIPPED_SPELLS = 8

@onready var vbox: VBoxContainer = %LearnedSpells
@onready var spellEquip: GridContainer = %SpellEquipmentContainer

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_populate_both.bind().call_deferred)
	_populate_both()

func _populate_both() -> void:
	await _populate_learned()
	await _populate_equipped()

func _populate_learned() -> void:
	for child in vbox.get_children():
		child.queue_free()
	await get_tree().process_frame
	for spell in Player_Global_Data.learned_spells:
		if Player_Global_Data.is_spell_equipped(spell):
			continue
		var slot = SPELL_SLOT.instantiate()
		vbox.add_child(slot)
		slot.set_spell(spell, false)
		slot.spell_selected.connect(_on_learned_spell_selected)

func _populate_equipped() -> void:
	for child in spellEquip.get_children():
		child.queue_free()
	await get_tree().process_frame
	for spell in Player_Global_Data.equipped_spells:
		var slot = SPELL_SLOT.instantiate()
		spellEquip.add_child(slot)
		slot.set_spell(spell, true)
		slot.spell_selected.connect(_on_equipped_spell_selected)

func _on_learned_spell_selected(spell: SpellData) -> void:
	if Player_Global_Data.equipped_spells.size() >= MAX_EQUIPPED_SPELLS:
		push_warning("Cannot equip more than %d spells." % MAX_EQUIPPED_SPELLS)
		return
	Player_Global_Data.equip_spell(spell)

func _on_equipped_spell_selected(spell: SpellData) -> void:
	Player_Global_Data.unequip_spell(spell)

func _on_back_button_pressed() -> void:
	var prev := Player_Manager.current_scene
	if prev == "":
		prev = Player_Manager.previous_scene_path
	if prev == "":
		push_error("SpellEquipView: No scene stored in Player_Manager.")
		return
	if SceneManager:
		SceneManager.change_scene(prev)
		Player_Global_Data.p_moveable = true
	else:
		push_error("SpellEquipView: SceneManager not found!")
