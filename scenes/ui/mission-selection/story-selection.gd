extends Control
@export var destination_scene: PackedScene
@export var next_scene_id: String

func _on_button_pressed() -> void:
	if next_scene_id == "":
		push_error("FAILED: next_scene_id is empty in the Inspector!")
		return
	
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	
	if not scene_data:
		push_error("FAILED: Scene_Registry could not find ID: " + next_scene_id)
		print("Available IDs: ", Scene_Registry.scenes.keys())
		return
	
	SceneManager.change_scene(scene_data.scene.resource_path)

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
