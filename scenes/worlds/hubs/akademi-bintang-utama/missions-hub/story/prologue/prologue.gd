extends Node

@export var timeline_1: DialogicTimeline
@export var timeline_2: DialogicTimeline
@export var timeline_3: DialogicTimeline
@export var next_scene_id: String

@export var required_signal_to_advance: String = "route_selected"

func _ready() -> void:
	start_sequence()

func start_sequence() -> void:
	# Timelines 1
	Dialogic.start(timeline_1)
	await Dialogic.timeline_ended
	print("end of, timeline 1")
	
	
	
	# Scene Change with Safety Check
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	

	# CHECK: Does the ID exist in the registry?
	if scene_data == null:
		push_error("FAILED: next_scene_id '" + next_scene_id + "' not found in Scene_Registry!")
		return
		
	# CHECK: Does the data have a 'scene' property that is a PackedScene?
	if scene_data.scene == null:
		push_error("FAILED: The scene data for '" + next_scene_id + "' exists, but the 'scene' property is empty!")
		return
	
	Player_Global_Data.p_moveable = true
	
	# If both pass, proceed to change scene
	await SceneManager.change_scene(scene_data.scene.resource_path)
	
# Helper function to filter global signals
func wait_for_custom_signal(target_name: String):
	while true:
		var emitted_name = await Player_Global_Data.custom_signal_emitted
		if emitted_name == target_name:
			# 4. Wait for signal
				await wait_for_custom_signal(required_signal_to_advance)
				Dialogic.start(timeline_3)
