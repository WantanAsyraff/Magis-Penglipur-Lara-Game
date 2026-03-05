extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")
const MAX_EQUIPPED_SPELLS = 8

@export var next_scene_id: String
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
	print("--- Transition Attempt Started ---")
	print("Target ID: ", next_scene_id)
	if next_scene_id == "":
		push_error("FAILED: next_scene_id is empty in the Inspector!")
		return
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	if not scene_data:
		push_error("FAILED: Scene_Registry could not find ID: " + next_scene_id)
		print("Available IDs: ", Scene_Registry.scenes.keys())
		return
	print("SUCCESS: Found path: ", scene_data.scene.resource_path)
	if SceneManager:
		SceneManager.change_scene(scene_data.scene.resource_path)
	else:
		push_error("FAILED: SceneManager Autoload not found!")
