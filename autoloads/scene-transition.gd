class_name SceneTransition
extends Node

var current_scene_path: String = ""
var previous_scene_path: String = ""
var target_spawn_point: String = "entrance"

var current_scene_node: Node = null

func _ready():
	current_scene_node = get_tree().current_scene
	if current_scene_node:
		current_scene_path = current_scene_node.scene_file_path
		print("Initial scene set to:", current_scene_path)

func change_scene(new_scene_path: String, spawn_point: String) -> void:
	previous_scene_path = current_scene_path
	current_scene_path = new_scene_path
	target_spawn_point = spawn_point

	print("Changing scene to:", new_scene_path)
	print("Previous scene was:", previous_scene_path)
	print("Target spawn:", target_spawn_point)

	# Load new scene pack
	var new_packed: PackedScene = ResourceLoader.load(new_scene_path)
	if not new_packed:
		push_error("Failed loading: " + new_scene_path)
		return

	# Instance but do NOT free yet
	var new_node = new_packed.instantiate()

	# Add to root viewport so it becomes the main scene
	get_tree().get_root().get_child(0).add_child(new_node)
	get_tree().current_scene = new_node

	# Then free the old scene after
	if current_scene_node:
		current_scene_node.queue_free()

	current_scene_node = new_node

	# Spawn player now that scene is in tree
	_spawn_player_in_scene()


func _spawn_player_in_scene():
	if not current_scene_node:
		push_error("No current scene to spawn player in!")
		return

	# Use recursive search in case SpawnPoints is nested
	var spawn_points = current_scene_node.find_child("SpawnPoints", true, false)
	if not spawn_points:
		push_warning("SpawnPoints node not found in scene: " + current_scene_path)
		return

	# Find the specific marker
	var spawn_marker = spawn_points.get_node_or_null(target_spawn_point)
	if not spawn_marker:
		push_warning("Spawn point '%s' not found, using (0,0)" % target_spawn_point)
		spawn_marker = Node2D.new()
		spawn_marker.position = Vector2.ZERO

	Player_Manager.spawn_player(current_scene_node, spawn_marker.global_position)

func go_back() -> void:
	# If no previous scene, warn
	if previous_scene_path == "":
		push_warning("No previous scene saved!")
		return

	# Print debugging
	print("Going back from:", current_scene_path)
	print("Loading previous:", previous_scene_path)
	print("Target spawn:", target_spawn_point)

	# Swap so new previous becomes current
	var load_path = previous_scene_path
	previous_scene_path = current_scene_path
	current_scene_path = load_path

	# Free current scene node
	if current_scene_node:
		current_scene_node.queue_free()
		current_scene_node = null

	# Load and instantiate previous scene
	var scene_res = ResourceLoader.load(load_path)
	if not scene_res:
		push_error("Failed to load scene: " + load_path)
		return

	var scene_node = scene_res.instantiate()
	if not scene_node:
		push_error("Failed to instance scene: " + load_path)
		return

	# Add to viewport
	get_tree().get_root().get_child(0).add_child(scene_node)
	get_tree().current_scene = scene_node
	current_scene_node = scene_node

	# Now spawn player at saved spawn point
	_spawn_player_in_scene()
