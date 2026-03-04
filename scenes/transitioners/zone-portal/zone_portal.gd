extends Area2D

@export var is_door: bool = false
@export var next_scene_id: String = "world_id"
@export var spawn_marker_override: String = ""

var _triggered: bool = false
var _player_in_area: bool = false

func change_scene():
	if _triggered:
		return
	_triggered = true
	
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	Player_Global_Data.combat_mode = false
	if not scene_data:
		_triggered = false
		return
	
	# Use override or default from SceneData
	var spawn_marker = spawn_marker_override if spawn_marker_override else scene_data.default_spawn_marker
	
	# Set spawn marker BEFORE scene change
	if spawn_marker:
		Player_Manager.set_meta("next_spawn_marker", spawn_marker)
	
	# Use SceneManager's change_scene with await to prevent retriggering
	await SceneManager.change_scene(scene_data.scene.resource_path)
	
	print("Scene data changed: ", scene_data.scene.resource_path)

func _process(_delta: float) -> void:
	if is_door and _player_in_area and not _triggered:
		if Input.is_action_just_pressed("interact"):
			change_scene()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = true
		if not is_door and not _triggered:
			change_scene()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = false
