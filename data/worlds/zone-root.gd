extends Node

var _player_setup_done: bool = false

func _ready():
	# Use call_deferred to ensure the scene tree is fully ready
	call_deferred("_deferred_setup")

func _deferred_setup():
	if _player_setup_done:
		return
	_player_setup_done = true
	
	# Only setup player if it hasn't been spawned yet
	if not Player_Manager.player or not is_instance_valid(Player_Manager.player) or not Player_Manager.player.is_inside_tree():
		setup_player()
	else:
		# Player already exists, just reposition it
		reposition_existing_player()

func reposition_existing_player():
	var spawn_position = Vector2.ZERO
	
	# Get the spawn marker name
	var spawn_marker_name = "PlayerSpawn"
	if Player_Manager.has_meta("next_spawn_marker"):
		spawn_marker_name = Player_Manager.get_meta("next_spawn_marker")
		Player_Manager.remove_meta("next_spawn_marker")
	
	# Try to find the marker
	var spawn_marker = find_marker(spawn_marker_name)
	
	if spawn_marker:
		spawn_position = spawn_marker.global_position
	else:
		push_warning("Spawn marker '%s' not found, using (0,0)" % spawn_marker_name)
	
	# Just move the existing player
	if Player_Manager.player.get_parent():
		Player_Manager.player.get_parent().remove_child(Player_Manager.player)
	add_child(Player_Manager.player)
	Player_Manager.player.global_position = spawn_position
	print("Repositioned existing player to: ", spawn_position)

func setup_player():
	var spawn_position = Vector2.ZERO
	
	# Get the spawn marker name
	var spawn_marker_name = "PlayerSpawn"
	if Player_Manager.has_meta("next_spawn_marker"):
		spawn_marker_name = Player_Manager.get_meta("next_spawn_marker")
		Player_Manager.remove_meta("next_spawn_marker")
	
	# Try to find the marker
	var spawn_marker = find_marker(spawn_marker_name)
	
	if spawn_marker:
		spawn_position = spawn_marker.global_position
	else:
		push_warning("Spawn marker '%s' not found, using (0,0)" % spawn_marker_name)
	
	# Spawn/move player
	Player_Manager.spawn_player(self, spawn_position)

func find_marker(marker_name: String) -> Node2D:
	# Try exact name match first
	var marker = get_node_or_null(marker_name)
	if marker:
		return marker
	
	# Try searching recursively
	marker = find_child(marker_name, true, false)
	if marker:
		return marker
	
	# Try case-insensitive search
	for child in get_children():
		if child.name.to_lower() == marker_name.to_lower():
			return child
	
	return null
