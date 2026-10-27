class_name TrainingDummy
extends CharacterBody2D

@export var max_hp: float = 100.0
@export var flash_color: Color = Color(1, 0.2, 0.2)
@export var flash_duration: float = 0.1

var current_hp: float

const DAMAGE_INDICATOR = preload("res://components/damage-indicator/damage-indicator.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = get_node_or_null("HpLabel") as Label  # add a Label child named HpLabel

func _ready() -> void:
	current_hp = max_hp
	_update_hp_label()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp -= amount
	_spawn_indicator(amount)
	_flash()
	_update_hp_label()
	if current_hp <= 0:
		_die()

func _spawn_indicator(amount: float) -> void:
	var indicator = DAMAGE_INDICATOR.instantiate()
	indicator.text = str(snappedf(amount, 0.1))
	indicator.position = global_position + Vector2(randf_range(-10, 10), -40)
	get_tree().current_scene.add_child(indicator)

func _flash() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", flash_color, flash_duration)
	tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)

func _update_hp_label() -> void:
	if hp_label:
		hp_label.text = "%d / %d" % [current_hp, max_hp]

func _die() -> void:
	current_hp = max_hp
	_update_hp_label()
