extends CharacterBody2D

@export_group("Dialogic")
@export var npc_timeline: DialogicTimeline

@export_group("Overworld Transition")
## If true, the player will be moved to a new scene after the dialogue ends.
@export var is_overworld_npc: bool = false
## The scene to load if 'is_overworld_npc' is checked.
@export var destination_scene: PackedScene

var is_player_in_range: bool = false

func _input(event: InputEvent) -> void:
	# Check if player is nearby AND pressed the interact key
	if is_player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	# Ensure dialogue isn't already running
	if Dialogic.current_timeline == null:
		# 1. Stop Player Movement
		Player_Global_Data.p_moveable = false
		
		# 2. Start Conversation
		Dialogic.start(npc_timeline)
		
		# 3. Wait for the dialogue to finish
		await Dialogic.timeline_ended
		
		# 4. Handle Overworld Transition or Resume Movement
		if is_overworld_npc and destination_scene:
			print("Transitioning to new scene...")
			# Using SceneManager as per your previous logic
			# If SceneManager is an Autoload, we pass the resource_path
			Player_Global_Data.p_moveable = true
			await SceneManager.change_scene(destination_scene.resource_path)
			# Note: We don't necessarily need to set p_moveable = true here 
			# because the new scene will likely re-initialize the player.
		else:
			# Just let the player walk again if we aren't changing scenes
			Player_Global_Data.p_moveable = true

# --- Area Detection ---

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		print("Player in range of NPC")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		print("Player left range of NPC")
