extends Node

var current_scene_path: String = ""
var previous_scene_path: String = ""
var target_spawn_point: String = "entrance" # First spawn player. Must be Marker 2D

func change_scene(new_scene_path: String, spawn_point: String = "entrance"):
	# Save paths
	previous_scene_path = current_scene_path
	current_scene_path = new_scene_path

	# Save spawn point
	target_spawn_point = spawn_point

	print("Changing scene to:", new_scene_path)
	print("Previous scene was:", previous_scene_path)
	print("Target spawn:", target_spawn_point)

	get_tree().change_scene_to_file(new_scene_path)


func go_back():
	if previous_scene_path == "":
		push_warning("No previous scene saved!")
		return

	# Swap paths
	var temp := current_scene_path
	current_scene_path = previous_scene_path
	previous_scene_path = temp

	get_tree().change_scene_to_file(current_scene_path)
