#Zone portal.gd
extends Area2D

@export var next_scene_id: String = "world_id"
@export var spawn_marker_override: String = ""

var _triggered: bool = false

func change_scene():
	if _triggered:
		return
	_triggered = true
	
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	if not scene_data:
		_triggered = false
		return
	
	# Use override or default from SceneData
	var spawn_marker = spawn_marker_override if spawn_marker_override else scene_data.default_spawn_marker
	
	Player_Manager.set_meta("next_spawn_marker", spawn_marker)
	SceneManager.change_scene(scene_data.scene.resource_path)
	print("Scene data changed: ", scene_data.scene.resource_path)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _triggered:
		change_scene()

func _on_body_exited(body: Node2D) -> void:
	pass
