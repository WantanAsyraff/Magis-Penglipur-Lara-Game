extends Node

@export var timeline_1: DialogicTimeline
@export var timeline_2: DialogicTimeline
@export var timeline_3: DialogicTimeline
@export var next_scene_id: String

func _ready() -> void:
	start_sequence()

func start_sequence() -> void:
	# 1. Start the first timeline
	Dialogic.start(timeline_1)
	
	# 2. Wait for it to finish
	await Dialogic.timeline_ended
	
	# 3. Start the second
	Dialogic.start(timeline_2)
	# 4. Wait for it to finish
	await Dialogic.timeline_ended
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	await SceneManager.change_scene(scene_data.scene.resource_path)
	
	# 5. Start the third
	Dialogic.start(timeline_3)
