extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/after-final-paper.tres")
func _ready() -> void:
	if not SaveManager.loading: begin_intro()
func begin_intro() -> void:
	var contextual := sequence.duplicate() as CutsceneSequence
	contextual.phone_after = true
	CutsceneFlow.play(self,contextual)
