extends Node

@export var player_scene: PackedScene = preload("res://components/characters/player/player.tscn")
var player: Node2D = null
var _is_spawning: bool = false

func spawn_player(parent: Node, spawn_position: Vector2):
	if _is_spawning:
		print("Already spawning player, skipping...")
		return
	
	_is_spawning = true
	print("spawning player...")
	
	if not player_scene:
		push_error("Player scene not assigned in Player_Manager!")
		_is_spawning = false
		return
	
	if player and is_instance_valid(player):
		# Move existing player
		if player.get_parent():
			player.get_parent().remove_child(player)
		parent.add_child(player)
		player.global_position = spawn_position
		print("Moved existing player to new scene at position: ", spawn_position)
	else:
		# Spawn new player
		player = player_scene.instantiate()
		parent.add_child(player)
		print("Player spawned for the first time!")
		player.global_position = spawn_position
		print("player position at ", spawn_position)
	
	_is_spawning = false
