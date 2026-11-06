extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/after-final-paper.tres")
func _ready() -> void:
	if SaveManager.loading: return
	_complete_exam_arrival()
	begin_intro()

func _complete_exam_arrival() -> void:
	if StoryDirector.is_ready() and StoryDirector.get_current_stage_id() == &"prologue.spm_practical" and QuestManager.world_flags.get("story.prologue.practical_demonstrated", false) and Player_Manager.previous_scene_path == "res://scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn":
		QuestManager.set_world_flag("story.prologue.spm_completed", true)
func begin_intro() -> void:
	var contextual := sequence.duplicate() as CutsceneSequence
	contextual.phone_after = true
	CutsceneFlow.play(self,contextual)
