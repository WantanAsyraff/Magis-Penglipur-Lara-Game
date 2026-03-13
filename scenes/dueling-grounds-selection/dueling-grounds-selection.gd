class_name DuelingGrounds extends Control

@export var next_scene_id: String

func _on_button_pressed() -> void:
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
	if not scene_data.scene:
		push_error("FAILED: SceneData exists but has no scene assigned for ID: " + next_scene_id)
		return

	print("SUCCESS: Found path: ", scene_data.scene.resource_path)

	# Execute change
	if SceneManager:
		SceneManager.change_scene(scene_data.scene.resource_path)
	else:
		push_error("FAILED: SceneManager Autoload not found!")
