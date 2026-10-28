# Key.gd
# Requires: Area2D (this node), CollisionShape2D, Sprite2D/AnimatedSprite2D
# Player must be in group "player"
# Shows an interact prompt when player is nearby, picked up on interact press

class_name Key
extends Area2D

## Must match the key_id expected by the LockedDoor this key opens.
@export var key_id: String = "key_default"

@export var prompt_text: String = "Press [F] to pick up"

var _player_nearby: Node = null
var _prompt_label: Label = null

func _ready() -> void:
	if WorldPersistence.has_state(self,"collected"):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_prompt()

func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-60, -48)
	_prompt_label.visible = false
	add_child(_prompt_label)

func _process(_delta: float) -> void:
	if _player_nearby and Input.is_action_just_pressed("interact"):
		_pick_up()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_nearby = body
	_prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body != _player_nearby:
		return
	_player_nearby = null
	_prompt_label.visible = false

func _pick_up() -> void:
	# Store the key id in Player_Global_Data so doors can check it
	if not Player_Global_Data.has_meta("keys"):
		Player_Global_Data.set_meta("keys", [])
	var keys: Array = Player_Global_Data.get_meta("keys")
	if not keys.has(key_id):
		keys.append(key_id)
		Player_Global_Data.set_meta("keys", keys)
	WorldPersistence.mark(self,"collected")
	print("Picked up key: ", key_id)
	queue_free()
