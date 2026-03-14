extends CharacterBody2D

@export_group("Dialogic")
@export var npc_timeline: DialogicTimeline

@export_group("Overworld Transition")
@export var is_overworld_npc: bool = false
@export var destination_scene: PackedScene

@export_group("Tutorial")
@export var has_tutorial: bool = false
@export var tutorial_panel_scene: PackedScene
@export var tutorial_data: TutorialData

@export_group("Movement")
@export var is_moveable: bool = false
@export var move_speed: float = 60.0
@export var wander_radius: float = 80.0
@export var pause_duration: float = 2.0

@export_group("Label")
@export var interact_label_text: String = "E  to interact"

var is_player_in_range: bool = false
var _origin: Vector2
var _wander_target: Vector2
var _pause_timer: float = 0.0
var _is_paused: bool = true

@onready var interact_label: Label = $InteractLabel

func _ready() -> void:
	_origin = global_position
	_wander_target = global_position
	if interact_label:
		interact_label.text = interact_label_text
	_update_label_visibility()

func _physics_process(delta: float) -> void:
	if is_moveable and Dialogic.current_timeline == null:
		_handle_wander(delta)

func _handle_wander(delta: float) -> void:
	if _is_paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_is_paused = false
			_pick_new_target()
		return
	var direction := (_wander_target - global_position)
	if direction.length() < 4.0:
		velocity = Vector2.ZERO
		_is_paused = true
		_pause_timer = pause_duration
		move_and_slide()
		return
	velocity = direction.normalized() * move_speed
	move_and_slide()

func _pick_new_target() -> void:
	var angle := randf() * TAU
	var distance := randf() * wander_radius
	_wander_target = _origin + Vector2(cos(angle), sin(angle)) * distance

func _input(event: InputEvent) -> void:
	if is_player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if Dialogic.current_timeline == null:
		Player_Global_Data.p_moveable = false
		velocity = Vector2.ZERO
		_is_paused = true
		_pause_timer = pause_duration
		Dialogic.start(npc_timeline)
		await Dialogic.timeline_ended
		if has_tutorial and tutorial_panel_scene and tutorial_data:
			_show_tutorial()
			return
		_finish()

func _show_tutorial() -> void:
	var layer := CanvasLayer.new()
	var panel: PanelTutorial = tutorial_panel_scene.instantiate()
	panel.data = tutorial_data
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	get_tree().current_scene.add_child(layer)
	await panel.closed
	layer.queue_free()
	_finish()

func _finish() -> void:
	if is_overworld_npc and destination_scene:
		Player_Global_Data.p_moveable = true
		await SceneManager.change_scene(destination_scene.resource_path)
	else:
		Player_Global_Data.p_moveable = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		_update_label_visibility()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		_update_label_visibility()

func _update_label_visibility() -> void:
	if interact_label:
		interact_label.visible = is_player_in_range
