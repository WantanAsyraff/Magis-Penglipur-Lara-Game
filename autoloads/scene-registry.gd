extends Node

var scenes: Dictionary = {}

# Export-safe registry using explicit resource paths.
const SCENE_DATA_PATHS: PackedStringArray = [
	"res://data/worlds/hubs/akademi-bintang-utama/abu-campus-entrance.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/abu-courtyard.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/abu-library.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/dueling-grounds-selection.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/dueling-grounds.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/spell-tree.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/dormitory/abu-dorm-room.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/dormitory/abu-dormitory-hallway.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/dueling-grounds/dueling-selection.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/story/e-hailing.tres",
	"res://data/worlds/hubs/akademi-bintang-utama/story/missions-selection.tres"
	
]

func _ready() -> void:
	_load_all_scene_data()

func _load_all_scene_data() -> void:
	scenes.clear()
	for path in SCENE_DATA_PATHS:
		var scene_data = load(path) as SceneData
		if not scene_data:
			push_warning("SceneRegistry: Failed to load SceneData at %s" % path)
			continue
		_register_scene_data(scene_data)

func _register_scene_data(scene_data: SceneData) -> void:
	if not scene_data:
		push_warning("SceneRegistry: Null SceneData in SCENE_DATA_RESOURCES.")
		return
	if scene_data.scene_id.is_empty():
		push_warning("SceneRegistry: SceneData missing scene_id (%s)." % scene_data.resource_path)
		return
	scenes[scene_data.scene_id] = scene_data

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
