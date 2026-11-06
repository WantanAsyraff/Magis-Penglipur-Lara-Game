extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/school-entrance.tres")
func _ready() -> void:
	var receiver := get_node_or_null("GameComponents/Environment/school-environment/ChillTarget")
	if receiver != null and receiver.has_signal("activated"):
		receiver.activated.connect(_on_practical_receiver_activated)
	if not SaveManager.loading:
		_record_school_arrival()
		begin_intro()

func _record_school_arrival() -> void:
	if not SaveManager.loading and StoryDirector.is_ready() and StoryDirector.get_current_stage_id() == &"prologue.leave_house" and Player_Manager.previous_scene_path == "res://scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn":
		var arrival := GameplayEvent.new(GameplayEvent.Type.LOCATION_REACHED, "prologue.school_entrance", 1, QuestManager.active_owner_id)
		if QuestManager.publish(arrival):
			QuestManager.set_world_flag("story.prologue.left_house", true)
			QuestManager.set_world_flag("story.prologue.reached_school", true)

func _on_practical_receiver_activated(active: bool) -> void:
	if active and not SaveManager.loading and StoryDirector.is_ready() and StoryDirector.get_current_stage_id() == &"prologue.spm_practical":
		QuestManager.set_world_flag("story.prologue.practical_demonstrated", true)
func begin_intro() -> void:
	CutsceneFlow.play(self,sequence)
