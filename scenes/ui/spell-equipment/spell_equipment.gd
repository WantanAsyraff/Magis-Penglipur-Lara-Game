extends Control


const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")

@export var next_scene_id: String
@onready var vbox: VBoxContainer = %VBoxContainer

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_populate_vbox)
	_populate_vbox()

func _populate_vbox() -> void:
	for child in vbox.get_children():
		child.free()
	for spell in Player_Global_Data.learned_spells:
		var slot = SPELL_SLOT.instantiate()
		vbox.add_child(slot)
		slot.set_spell(spell)
		slot.spell_selected.connect(_on_spell_selected)

func _on_spell_selected(spell: SpellData) -> void:
	print(spell.spell_name) # replace with whatever you want to do


func _on_back_button_pressed() -> void:
	print("--- Transition Attempt Started ---")
	print("Target ID: ", next_scene_id)
	
	if next_scene_id == "":
		push_error("FAILED: next_scene_id is empty in the Inspector!")
		return

	var scene_data = Scene_Registry.get_scene(next_scene_id)
	
	if not scene_data:
		push_error("FAILED: Scene_Registry could not find ID: " + next_scene_id)
		# Print all known IDs so you can see if there is a typo
		print("Available IDs: ", Scene_Registry.scenes.keys()) 
		return

	print("SUCCESS: Found path: ", scene_data.scene.resource_path)

	# Execute change
	if SceneManager:
		SceneManager.change_scene(scene_data.scene.resource_path)
	else:
		push_error("FAILED: SceneManager Autoload not found!")
