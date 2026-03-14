extends Node

var _player_setup_done: bool = false

func _ready() -> void:
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if _player_setup_done:
		return
	_player_setup_done = true

	_update_world_label()

	var spawn_position := _get_spawn_position()

	if not multiplayer.has_multiplayer_peer():
		Player_Manager.spawn_player(self, spawn_position)
		return

	if multiplayer.is_server():
		Player_Manager.spawn_player_for_peer(self, spawn_position, 1)
		for peer_id in multiplayer.get_peers():
			Player_Manager.spawn_player_for_peer(self, spawn_position, int(peer_id))

func _update_world_label() -> void:
	for scene_data in Scene_Registry.scenes.values():
		if scene_data.scene and scene_data.scene.resource_path == scene_file_path:
			Player_Global_Data.current_world = scene_data.scene_name
			return
	push_warning("ZoneRoot: No SceneData found matching scene path: %s" % scene_file_path)

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
