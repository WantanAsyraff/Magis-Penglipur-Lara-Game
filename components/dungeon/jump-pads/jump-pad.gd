class_name JumpPad
extends Area2D

@export var launch_force: float = 2800.0
@export var launch_angle: float = 90.0  # degrees, 90 = straight up

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	var angle_rad := deg_to_rad(launch_angle)
	var launch_dir := Vector2(cos(angle_rad), -sin(angle_rad))  # Flip Y for Godot coords
	body.velocity = launch_dir * launch_force

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("bounce"):
		sprite.play("bounce")
