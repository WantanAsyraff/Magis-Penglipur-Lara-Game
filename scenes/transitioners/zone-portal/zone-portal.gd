class_name ZonePortal
extends Area2D

@export var target_zone: ZoneData
@export var target_spawn_point: String = "entrance"

var player_in_range := false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_change_zone()

func _change_zone():
	if not target_zone or not target_zone.zone_scene:
		push_error("Invalid target zone!")
		return

	Scene_Transition.change_scene(
		target_zone.zone_scene.resource_path,
		target_spawn_point
	)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		print("Player entered")
		player_in_range = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		print("Player exited")
		player_in_range = false
