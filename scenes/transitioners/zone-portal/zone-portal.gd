class_name ZonePortal
extends Area2D

@export var target_zone: ZoneData
@export var target_spawn_point: String = ""
@export_multiline var preview_text: String = "Press [E] to Enter"

var player_in_range := false
var preview_label: Label

func _ready() -> void:
	_create_label()
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_change_zone()

func _change_zone() -> void:
	if not target_zone or not target_zone.zone_scene:
		push_error("Invalid target zone!")
		return

	Scene_Transition.change_scene(
		target_zone.zone_scene.resource_path,
		target_spawn_point
	)

# -------------------------
# PREVIEW LABEL
# -------------------------
func _create_label() -> void:
	preview_label = Label.new()
	preview_label.text = preview_text
	preview_label.visible = false
	preview_label.z_index = 100

	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Position above the portal
	preview_label.position = Vector2(0, -40)

	add_child(preview_label)

# -------------------------
# SIGNALS
# -------------------------
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		preview_label.visible = true
		print("Player entered portal")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		preview_label.visible = false
		print("Player exited portal")
