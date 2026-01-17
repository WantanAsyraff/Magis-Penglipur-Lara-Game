extends Node

var current_scene_path: String = ""
var previous_scene_path: String = ""
var target_spawn_point: String = "entrance"

func go_back():
	print("Current scene: ", current_scene_path)
	print("Previous scene: ", previous_scene_path)

	if previous_scene_path == "":
		push_warning("No previous scene saved!")
		return

	 # Swap current and previous for consistency
	var temp := current_scene_path
	current_scene_path = previous_scene_path
	previous_scene_path = temp

	get_tree().change_scene(current_scene_path)
