extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/school-entrance.tres")
func _ready() -> void:
	if not SaveManager.loading: begin_intro()
func begin_intro() -> void:
	CutsceneFlow.play(self,sequence)
