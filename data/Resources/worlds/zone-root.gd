extends Node2D

func _ready():
	if not has_node("SpawnPoints"):
		push_error("Zone missing SpawnPoints!")
		return

	var spawn_name := Scene_Transition.target_spawn_point
	var spawn_points := $SpawnPoints

	if not spawn_points.has_node(spawn_name):
		push_warning("Spawn point '%s' not found!" % spawn_name)
		return

	var spawn := spawn_points.get_node(spawn_name) as Marker2D
	Player_Manager.spawn_player(self, spawn.global_position)
