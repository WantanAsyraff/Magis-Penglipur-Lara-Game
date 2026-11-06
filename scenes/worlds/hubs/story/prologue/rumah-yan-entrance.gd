extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/kampung-intro.tres")
func _ready() -> void:
	CutsceneFlow.sequence_finished.connect(_on_intro_finished)
	if not SaveManager.loading: begin_intro()
func begin_intro() -> void:
	CutsceneFlow.play(self,sequence)

func _on_intro_finished(finished: CutsceneSequence, outcome: int) -> void:
	if finished != sequence or outcome != CutsceneFlow.Outcome.INTERRUPTED or SaveManager.loading or is_queued_for_deletion(): return
	call_deferred("_retry_interrupted_intro")

func _retry_interrupted_intro() -> void:
	if not is_inside_tree() or SaveManager.loading or QuestManager.world_flags.get(CutsceneFlow.flag_for(sequence), false): return
	if Dialogic.current_timeline == null and CutsceneFlow.sequence == null:
		begin_intro()
	elif not Dialogic.timeline_ended.is_connected(_retry_interrupted_intro):
		Dialogic.timeline_ended.connect(_retry_interrupted_intro, CONNECT_ONE_SHOT)
