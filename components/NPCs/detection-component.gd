class_name DetectionComponent
extends Node

# -------------------------
# SIGNALS
# -------------------------
signal player_entered
signal player_exited
signal interacted

# -------------------------
# EXPORTS
# -------------------------
@export var interact_label_text: String = "E  to interact"

# -------------------------
# NODES
# -------------------------
@onready var _area: Area2D = %Area2D
var _label: Label

# -------------------------
# STATE
# -------------------------
var is_player_in_range: bool = false

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	_label = get_parent().get_node_or_null("%InteractLabel")
	if _label:
		_label.text = interact_label_text
	_update_label()
	if not _area:
		push_error("DetectionComponent: missing Area2D child.")

func _unhandled_input(event: InputEvent) -> void:
	if not is_player_in_range:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit()

# -------------------------
# AREA CALLBACKS
# -------------------------
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	is_player_in_range = true
	_update_label()
	player_entered.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	is_player_in_range = false
	_update_label()
	player_exited.emit()

# -------------------------
# LABEL
# -------------------------
func _update_label() -> void:
	if _label:
		_label.visible = is_player_in_range

func set_label_text(text: String) -> void:
	interact_label_text = text
	if _label:
		_label.text = text
