extends Node

@export var player_scene: PackedScene = preload("res://components/characters/player/player.tscn")
var player: Node2D = null

func spawn_player(parent: Node, spawn_position: Vector2):
	if not player_scene:
		push_error("Player scene not assigned in Player_Manager!")
		return

	if player and is_instance_valid(player):
		player.global_position = spawn_position
		return

	player = player_scene.instantiate()
	parent.add_child(player)
	player.global_position = spawn_position
