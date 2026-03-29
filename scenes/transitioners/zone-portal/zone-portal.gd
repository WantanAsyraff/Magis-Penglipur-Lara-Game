extends Area2D

@export var is_door: bool = false
@export var is_safe_zone: bool = false
@export var next_scene_id: String = "world_id"
@export var spawn_marker_override: String = ""

@export_group("Enter Label")
@export var label_fade_duration: float = 0.2

@onready var enter_label = %EnterLabel

var _triggered: bool = false
var _player_in_area: bool = false

func _ready() -> void:
	if enter_label:
		enter_label.modulate.a = 0.0

func _set_label_visible(show: bool) -> void:
	if not enter_label:
		return
	var tween = create_tween()
	tween.tween_property(enter_label, "modulate:a", 1.0 if show else 0.0, label_fade_duration)

func change_scene() -> void:
	if _triggered:
		return
	_triggered = true
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	Player_Global_Data.combat_mode = false
	if not scene_data:
		_triggered = false
		return
	if not scene_data.scene:
		push_error("ZonePortal: scene_id '%s' has no scene assigned." % next_scene_id)
		_triggered = false
		return
	var spawn_marker = spawn_marker_override if spawn_marker_override else scene_data.default_spawn_marker
	if spawn_marker:
		Player_Manager.set_meta("next_spawn_marker", spawn_marker)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		Player_Manager.last_player_position = player.global_position
		print("ZonePortal: saved player position ", Player_Manager.last_player_position)
	Player_Manager.previous_scene_path = get_tree().current_scene.scene_file_path
	await SceneManager.change_scene(scene_data.scene.resource_path)
	print("ZonePortal: transitioned to ", scene_data.scene.resource_path)

func _process(_delta: float) -> void:
	if is_door and _player_in_area and not _triggered:
		if Input.is_action_just_pressed("interact"):
			change_scene()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_area = true
	_set_label_visible(true)
	if is_safe_zone:
		Player_Global_Data.combat_mode = false
	if not is_door and not _triggered:
		change_scene()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_area = false
	_set_label_visible(false)
	if is_safe_zone:
		Player_Global_Data.combat_mode = true
