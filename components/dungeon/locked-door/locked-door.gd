# LockedDoor.gd
# Requires: StaticBody2D (this node), CollisionShape2D, AnimatedSprite2D (optional)
# Add an Area2D child named "InteractArea" with its own CollisionShape2D for the prompt range

class_name LockedDoor
extends StaticBody2D

## Must match the key_id on the Key that opens this door.
@export var key_id: String = "key_default"

@export var prompt_locked_text: String = "Locked. Find the key."
@export var prompt_unlocked_text: String = "Press [F] to open"

## If true, the door is removed when opened. If false, it plays an open animation and disables collision.
@export var destroy_on_open: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interact_area: Area2D = $InteractArea

var _player_nearby: Node = null
var _is_open: bool = false
var _prompt_label: Label = null

func _ready() -> void:
	add_to_group("world_interaction")
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	_setup_prompt()
	if WorldPersistence.has_state(self,"open"): _restore_open()

func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-80, -56)
	_prompt_label.visible = false
	add_child(_prompt_label)

func _process(_delta: float) -> void:
	if _is_open or _player_nearby == null:
		return

	# Update prompt text based on whether player has the key
	_prompt_label.text = prompt_unlocked_text if _player_has_key() else prompt_locked_text

	if Input.is_action_just_pressed("interact") and _player_has_key():
		_open_door()

func _on_interact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_nearby = body
	_prompt_label.visible = true

func _on_interact_area_body_exited(body: Node) -> void:
	if body != _player_nearby:
		return
	_player_nearby = null
	_prompt_label.visible = false

func _player_has_key() -> bool:
	if not Player_Global_Data.has_meta("keys"):
		return false
	var keys: Array = Player_Global_Data.get_meta("keys")
	return keys.has(key_id)

func _consume_key() -> void:
	if not Player_Global_Data.has_meta("keys"):
		return
	var keys: Array = Player_Global_Data.get_meta("keys")
	keys.erase(key_id)
	Player_Global_Data.set_meta("keys", keys)

func _restore_open() -> void:
	_is_open = true
	_prompt_label.visible = false
	if destroy_on_open: queue_free()
	else:
		collision.set_deferred("disabled",true)
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("open"): sprite.play("open")

func _open_door() -> void:
	WorldPersistence.mark(self,"open")
	_is_open = true
	_consume_key()
	_prompt_label.visible = false
	print("Door opened with key: ", key_id)

	if destroy_on_open:
		queue_free()
		return

	# Disable collision so player can pass through
	collision.set_deferred("disabled", true)

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("open"):
		sprite.play("open")

func blocks_combat_push(player: Node2D) -> bool:
	return not _is_open and _player_nearby == player
