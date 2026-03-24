class_name ElevatorPortal
extends Area2D

# -------------------------
# EXPORTS
# -------------------------
@export var floors: Array[ElevatorFloor] = []
@export var elevator_ui_scene: PackedScene
@export var use_locking: bool = true

@export_group("Spawn Override")
@export var spawn_marker_override: String = ""

@export_group("Enter Label")
@export var label_fade_duration: float = 0.2

# -------------------------
# NODES
# -------------------------
@onready var enter_label: Label = %EnterLabel

# -------------------------
# STATE
# -------------------------
var _player_in_area: bool = false
var _ui_open: bool = false
var _triggered: bool = false

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	if enter_label:
		enter_label.modulate.a = 0.0

# -------------------------
# INPUT
# -------------------------
func _process(_delta: float) -> void:
	if _player_in_area and not _ui_open and not _triggered:
		if Input.is_action_just_pressed("interact"):
			_open_ui()

# -------------------------
# LABEL
# -------------------------
func _set_label_visible(show: bool) -> void:
	if not enter_label:
		return
	var tween := create_tween()
	tween.tween_property(enter_label, "modulate:a", 1.0 if show else 0.0, label_fade_duration)

# -------------------------
# AREA SIGNALS
# -------------------------
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = true
		_set_label_visible(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = false
		_set_label_visible(false)
		if _ui_open:
			_close_ui()

# -------------------------
# UI
# -------------------------
func _open_ui() -> void:
	if not elevator_ui_scene:
		push_error("ElevatorPortal: elevator_ui_scene is not assigned.")
		return

	_ui_open = true
	Player_Global_Data.p_moveable = false

	var ui := elevator_ui_scene.instantiate() as ElevatorUI
	if not ui:
		push_error("ElevatorPortal: elevator_ui_scene must be an ElevatorUI.")
		_ui_open = false
		Player_Global_Data.p_moveable = true
		return

	var floor_list := floors
	if not use_locking:
		floor_list = []
		for f in floors:
			var copy := f.duplicate() as ElevatorFloor
			copy.locked = false
			floor_list.append(copy)

	ui.setup(floor_list)
	ui.floor_selected.connect(_on_floor_selected)
	ui.cancelled.connect(_close_ui)
	get_tree().root.add_child(ui)

func _close_ui() -> void:
	_ui_open = false
	Player_Global_Data.p_moveable = true
	var ui := get_tree().root.get_node_or_null("ElevatorUI")
	if ui:
		ui.queue_free()

# -------------------------
# SCENE TRANSITION
# -------------------------
func _on_floor_selected(scene_id: String, spawn_marker: String) -> void:
	if _triggered:
		return
	_triggered = true

	_close_ui()

	var scene_data := Scene_Registry.get_scene(scene_id)
	Player_Global_Data.combat_mode = false

	if not scene_data:
		_triggered = false
		return
	if not scene_data.scene:
		push_error("ElevatorPortal: scene_id '%s' has no scene assigned." % scene_id)
		_triggered = false
		return

	# Priority: portal override > floor's spawn_marker > scene default
	var marker: String
	if spawn_marker_override:
		marker = spawn_marker_override
	elif spawn_marker:
		marker = spawn_marker
	else:
		marker = scene_data.default_spawn_marker

	if marker:
		Player_Manager.set_meta("next_spawn_marker", marker)

	# Save position directly from player group before transition
	var player := get_tree().get_first_node_in_group("player")
	if player:
		Player_Manager.last_player_position = player.global_position
		print("ElevatorPortal: saved player position ", Player_Manager.last_player_position)

	Player_Manager.previous_scene_path = get_tree().current_scene.scene_file_path
	await SceneManager.change_scene(scene_data.scene.resource_path)
	print("ElevatorPortal: transitioned to ", scene_data.scene.resource_path)
