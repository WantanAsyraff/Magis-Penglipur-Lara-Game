extends CharacterBody2D

@export var npc_timeline: DialogicTimeline
var is_player_in_range: bool = false

func _input(event):
	# Check if player is nearby AND pressed the interact key
	if is_player_in_range and event.is_action_pressed("interact"): # is usually Space/Enter/E
		start_dialogue()

func start_dialogue():
	# Ensure dialogue isn't already running
	if Dialogic.current_timeline == null:
		Dialogic.start(npc_timeline)
		Player_Global_Data.p_moveable = false
		await Dialogic.timeline_ended
		Player_Global_Data.p_moveable = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): # Make sure your Player node is in the "player" group
		is_player_in_range = true
		print("Player entered npc")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		print("Player entered npc")
