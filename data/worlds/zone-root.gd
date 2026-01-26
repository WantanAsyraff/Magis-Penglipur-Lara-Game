extends Node

var _player_setup_done: bool = false

func _ready() -> void:
	# Use deferred so marker nodes are ready
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _player_setup_done:
		return
	_player_setup_done = true

	var spawn_position := _get_spawn_position()

	# -------------------------------------------------
	# SINGLEPLAYER / OFFLINE
	# -------------------------------------------------
	if not multiplayer.has_multiplayer_peer():
		# Old behavior: spawn/move local player immediately
		Player_Manager.spawn_player(self, spawn_position)
		return

	# -------------------------------------------------
	# MULTIPLAYER
	# IMPORTANT:
	# - Clients MUST NOT spawn "local player" here because
	#   multiplayer.get_unique_id() can still be 1 before fully connected,
	#   causing the client to spawn authority=1 (host) and control the host.
	# - Server controls spawning; clients spawn via RPC from NetworkManager.
	# -------------------------------------------------
	if multiplayer.is_server():
		# Ensure host exists in this zone
		Player_Manager.spawn_player_for_peer(self, spawn_position, 1)

		# Optional: if peers already connected and you loaded/changed this zone,
		# you can reposition/spawn them too.
		for peer_id in multiplayer.get_peers():
			Player_Manager.spawn_player_for_peer(self, spawn_position, int(peer_id))

	# Clients do nothing here. They wait for server RPCs (rpc_spawn_player / rpc_spawn_existing).

func _get_spawn_position() -> Vector2:
	var spawn_marker_name := "PlayerSpawn"
	if Player_Manager.has_meta("next_spawn_marker"):
		spawn_marker_name = str(Player_Manager.get_meta("next_spawn_marker"))
		Player_Manager.remove_meta("next_spawn_marker")

	var marker := find_marker(spawn_marker_name)
	if marker:
		return marker.global_position

	push_warning("Spawn marker '%s' not found, using (0,0)" % spawn_marker_name)
	return Vector2.ZERO

func find_marker(marker_name: String) -> Node2D:
	var marker := get_node_or_null(marker_name)
	if marker and marker is Node2D:
		return marker

	marker = find_child(marker_name, true, false)
	if marker and marker is Node2D:
		return marker

	for child in get_children():
		if child.name.to_lower() == marker_name.to_lower() and child is Node2D:
			return child

	return null
