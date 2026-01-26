extends Node

@export var player_scene: PackedScene = preload("res://components/characters/player/player.tscn")

# Multiplayer: peer_id -> Player node
var players: Dictionary = {}

# Prevent double-spawn during fast scene transitions
var _is_spawning: bool = false

func get_local_peer_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1

func get_local_player() -> Node2D:
	var id := get_local_peer_id()
	if players.has(id) and is_instance_valid(players[id]):
		return players[id]
	return null



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
	if _is_spawning:
		print("Already spawning player, skipping...")
		return players.get(peer_id, null)

	_is_spawning = true

	if not player_scene:
		push_error("Player scene not assigned in Player_Manager!")
		_is_spawning = false
		return null

	# If exists, move/reparent + reposition
	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		var p: Node2D = players[peer_id]

		# Reparent if needed
		if p.get_parent() != parent:
			if p.get_parent():
				p.get_parent().remove_child(p)
			parent.add_child(p)

		p.global_position = spawn_position
		print("Moved existing player for peer:", peer_id, "to", spawn_position)

		_is_spawning = false
		return p

	# Spawn new player
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
 
