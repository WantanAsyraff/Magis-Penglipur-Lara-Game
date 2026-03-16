extends CharacterBody2D



# ─────────────────────────────────────────
# DIALOGIC
# ─────────────────────────────────────────
@export_group("Dialogic")
## If false, interacting with this NPC skips dialogue entirely.
@export var use_dialogic: bool = true
@export var npc_timeline: DialogicTimeline

# ─────────────────────────────────────────
# VISUALS
# ─────────────────────────────────────────
@export_group("Visuals")
@export var npc_sprite: Texture2D:
	set(value):
		npc_sprite = value
		if is_inside_tree() and sprite:
			sprite.texture = value

# ─────────────────────────────────────────
# OVERWORLD TRANSITION
# ─────────────────────────────────────────
@export_group("Overworld Transition")
@export var is_overworld_npc: bool = false
@export var destination_scene: PackedScene

# ─────────────────────────────────────────
# TUTORIAL
# ─────────────────────────────────────────
@export_group("Tutorial")
@export var has_tutorial: bool = false
@export var tutorial_panel_scene: PackedScene
@export var tutorial_data: TutorialData

# ─────────────────────────────────────────
# MOVEMENT
# ─────────────────────────────────────────
@export_group("Movement")
@export var is_moveable: bool = false
@export var move_speed: float = 60.0
@export var wander_radius: float = 80.0
@export var pause_duration: float = 2.0

# ─────────────────────────────────────────
# LABEL
# ─────────────────────────────────────────
@export_group("Label")
@export var interact_label_text: String = "E  to interact"

# ─────────────────────────────────────────
# RUNTIME
# ─────────────────────────────────────────
var is_player_in_range: bool = false
var _origin: Vector2
var _wander_target: Vector2
var _pause_timer: float = 0.0
var _is_paused: bool = true
var _dialogue_open: bool = false

@onready var interact_label: Label = $InteractLabel
@onready var sprite: Sprite2D = $Sprite2D

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_origin = global_position
	_wander_target = global_position

	if interact_label:
		interact_label.text = interact_label_text
	_update_label_visibility()

	# Apply exported sprite texture if set
	if npc_sprite and sprite:
		sprite.texture = npc_sprite

func _physics_process(delta: float) -> void:
	if is_moveable and not _dialogue_open:
		if use_dialogic and Dialogic.current_timeline != null:
			return
		_handle_wander(delta)

# ─────────────────────────────────────────
# WANDER
# ─────────────────────────────────────────
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

# ─────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if is_player_in_range and event.is_action_pressed("interact"):
		if _dialogue_open:
			_close_dialogue()
		else:
			start_dialogue()

# ─────────────────────────────────────────
# DIALOGUE
# ─────────────────────────────────────────
func start_dialogue() -> void:
	if _dialogue_open:
		return

	_dialogue_open = true
	Player_Global_Data.p_moveable = false
	velocity = Vector2.ZERO
	_is_paused = true
	_pause_timer = pause_duration

	if use_dialogic:
		if npc_timeline == null:
			push_warning("NPC: use_dialogic is true but no npc_timeline assigned.")
			_dialogue_open = false
			Player_Global_Data.p_moveable = true
			return
		if Dialogic.current_timeline != null:
			return
		Dialogic.start(npc_timeline)
		await Dialogic.timeline_ended
	# If use_dialogic is false, skip straight to post-dialogue logic

	_dialogue_open = false

	if has_tutorial and tutorial_panel_scene and tutorial_data:
		_show_tutorial()
		return

	_finish()

func _close_dialogue() -> void:
	if not _dialogue_open:
		return
	if use_dialogic and Dialogic.current_timeline != null:
		Dialogic.end_timeline()
	_dialogue_open = false
	Player_Global_Data.p_moveable = true
	_finish()

# ─────────────────────────────────────────
# TUTORIAL
# ─────────────────────────────────────────
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

# ─────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────
func _finish() -> void:
	Player_Global_Data.p_moveable = true
	if is_overworld_npc and destination_scene:
		await SceneManager.change_scene(destination_scene.resource_path)

# ─────────────────────────────────────────
# DETECTION
# ─────────────────────────────────────────
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
