extends Node2D

func _ready():
	# Find SpawnPoints anywhere in the scene
	var spawn_points := find_child("SpawnPoints", true, false)
	if spawn_points == null:
		push_error("Zone missing SpawnPoints!")
		return
	print("Spawn points found:", spawn_points.name)

	var spawn_name := Scene_Transition.target_spawn_point

	# Use get_node_or_null for safety
	var spawn := spawn_points.get_node_or_null(spawn_name)
	if spawn == null:
		push_warning("Spawn point '%s' not found!" % spawn_name)
		return

	Player_Manager.spawn_player(self, spawn.global_position)
	print("Player spawned at:", spawn.global_position)
