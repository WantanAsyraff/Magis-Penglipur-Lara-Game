extends Node

@export var player_scene: PackedScene = preload("res://components/characters/player/player.tscn")

var players: Dictionary = {} # peer_id -> Player


# -------------------------------------------------
# SINGLEPLAYER / LEGACY ENTRY POINT
# -------------------------------------------------
func spawn_player(parent: Node, spawn_position: Vector2) -> Node2D:
	var peer_id := 1
	if multiplayer.has_multiplayer_peer():
		peer_id = multiplayer.get_unique_id()

	return spawn_player_for_peer(parent, spawn_position, peer_id)


# -------------------------------------------------
# MULTIPLAYER ENTRY POINT
# -------------------------------------------------
func spawn_player_for_peer(parent: Node, spawn_position: Vector2, peer_id: int) -> Node2D:
	if not player_scene:
		push_error("Player scene not assigned in Player_Manager!")
		return null

	# If exists, just move it
	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		var p: Node2D = players[peer_id]
		p.global_position = spawn_position
		return p

	var player := player_scene.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)

	parent.add_child(player)
	player.global_position = spawn_position
	players[peer_id] = player

	print("Spawned player for peer:", peer_id, "at", spawn_position)
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
