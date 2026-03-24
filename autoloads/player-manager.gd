extends Node

@export var player_scene: PackedScene = preload("res://components/characters/player/player.tscn")

var players: Dictionary = {}
var _is_spawning: bool = false
var previous_scene_path: String = ""
var last_player_position: Vector2 = Vector2.ZERO

# Tracks current scene and player coords together
var current_scene: String = ""
var current_player_position: Vector2 = Vector2.ZERO

func get_local_peer_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1

func get_local_player() -> Node2D:
	var id := get_local_peer_id()
	if players.has(id) and is_instance_valid(players[id]):
		return players[id]
	return null

func save_player_position() -> void:
	var player := get_local_player()
	if player:
		last_player_position = player.global_position
		print("Player_Manager: saved position ", last_player_position)

func save_current_state(scene_path: String) -> void:
	current_scene = scene_path
	var player := get_local_player()
	if player:
		current_player_position = player.global_position
	print("Player_Manager: saved state — scene: ", current_scene, " pos: ", current_player_position)

func spawn_player(parent: Node, spawn_position: Vector2) -> Node2D:
	var peer_id := 1
	if multiplayer.has_multiplayer_peer():
		peer_id = multiplayer.get_unique_id()
	return spawn_player_for_peer(parent, spawn_position, peer_id)

func spawn_player_for_peer(parent: Node, spawn_position: Vector2, peer_id: int) -> Node2D:
	if _is_spawning:
		print("Already spawning player, skipping...")
		return players.get(peer_id, null)
	_is_spawning = true

	if not player_scene:
		push_error("Player scene not assigned in Player_Manager!")
		_is_spawning = false
		return null

	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		var p: Node2D = players[peer_id]
		if p.get_parent() != parent:
			if p.get_parent():
				p.get_parent().remove_child(p)
			parent.add_child(p)
		p.global_position = spawn_position
		print("Moved existing player for peer:", peer_id, "to", spawn_position)
		_is_spawning = false
		return p

	var player := player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	parent.add_child(player)
	player.global_position = spawn_position
	players[peer_id] = player
	print("Spawned player for peer:", peer_id, "at", spawn_position)
	_is_spawning = false
	return player

func remove_player(peer_id: int) -> void:
	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		players[peer_id].queue_free()
	players.erase(peer_id)

func clear_all() -> void:
	for peer_id in players.keys():
		if is_instance_valid(players[peer_id]):
			players[peer_id].queue_free()
	players.clear()
