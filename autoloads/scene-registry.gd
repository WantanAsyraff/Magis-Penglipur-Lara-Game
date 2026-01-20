# scenes_registry.gd (Autoload as "ScenesRegistry")
extends Node

var scenes: Dictionary = {}

func _ready():
	_load_all_scene_data()

func _load_all_scene_data():
	var base_path = "res://data/worlds/hubs/"
	_load_scene_data_recursive(base_path)

func _load_scene_data_recursive(path: String):
	var dir = DirAccess.open(path)
	
	if not dir:
		push_error("Failed to open directory: " + path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + file_name
		
		# Skip hidden files and special directories
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		# If it's a directory, recurse into it
		if dir.current_is_dir():
			_load_scene_data_recursive(full_path + "/")
		
		# If it's a .tres file, load it
		elif file_name.ends_with(".tres"):
			var scene_data = load(full_path) as SceneData
			
			if scene_data and scene_data.scene_id:
				scenes[scene_data.scene_id] = scene_data
				print("Loaded scene: ", scene_data.scene_id, " from ", full_path)
			else:
				push_warning("Invalid SceneData in: " + full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

# API Methods (same as before)
func get_scene(scene_id: String) -> SceneData:
	if scenes.has(scene_id):
		return scenes[scene_id]
	push_error("Scene '%s' not found in registry!" % scene_id)
	return null

func get_scene_path(scene_id: String) -> String:
	var scene_data = get_scene(scene_id)
	return scene_data.scene.resource_path if scene_data else ""

func get_all_scene_ids() -> Array:
	return scenes.keys()

func scene_exists(scene_id: String) -> bool:
	return scenes.has(scene_id)
