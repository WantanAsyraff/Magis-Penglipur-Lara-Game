# SceneRegistry.gd
extends Node

var scenes: Dictionary = {}

# ─────────────────────────────────────────
# SCENE HISTORY
# ─────────────────────────────────────────
var _current_scene_id: String = ""
var _previous_scene_id: String = ""

func set_current_scene(scene_id: String) -> void:
	if scene_id == _current_scene_id:
		return
	_previous_scene_id = _current_scene_id
	_current_scene_id = scene_id

func get_current_scene_id() -> String:
	return _current_scene_id

func get_previous_scene_id() -> String:
	return _previous_scene_id

func has_previous_scene() -> bool:
	return not _previous_scene_id.is_empty()

# ─────────────────────────────────────────
# FEEDING API
# ─────────────────────────────────────────
func register_paths(paths: PackedStringArray) -> void:
	for path in paths:
		var scene_data := load(path) as SceneData
		if not scene_data:
			push_warning("SceneRegistry: Failed to load SceneData at '%s'." % path)
			continue
		_register_scene_data(scene_data)

func unregister_paths(paths: PackedStringArray) -> void:
	for path in paths:
		var scene_data := load(path) as SceneData
		if scene_data and scenes.has(scene_data.scene_id):
			scenes.erase(scene_data.scene_id)

# ─────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────
func _register_scene_data(scene_data: SceneData) -> void:
	if scene_data.scene_id.is_empty():
		push_warning("SceneRegistry: SceneData at '%s' has no scene_id — skipped." % scene_data.resource_path)
		return
	if scenes.has(scene_data.scene_id):
		push_warning("SceneRegistry: Duplicate scene_id '%s' from '%s' — overwriting." % [scene_data.scene_id, scene_data.resource_path])
	scenes[scene_data.scene_id] = scene_data

# ─────────────────────────────────────────
# QUERY API
# ─────────────────────────────────────────
func get_scene(scene_id: String) -> SceneData:
	if scenes.has(scene_id):
		return scenes[scene_id]
	push_error("SceneRegistry: scene_id '%s' not found." % scene_id)
	return null

func get_scene_path(scene_id: String) -> String:
	var scene_data := get_scene(scene_id)
	return scene_data.scene.resource_path if scene_data else ""

func get_all_scene_ids() -> Array:
	return scenes.keys()

func scene_exists(scene_id: String) -> bool:
	return scenes.has(scene_id)

func clear() -> void:
	scenes.clear()
