extends Node2D
@export var sequence: CutsceneSequence = preload("res://data/story/after-final-paper.tres")
func _ready() -> void:
	if not SaveManager.loading: begin_intro()
func begin_intro() -> void:
	var trigger := get_node_or_null("StoryCutsceneTrigger") as StoryCutsceneTrigger
	if trigger and StoryDirector.is_ready():
		trigger.sequence = sequence
		trigger.try_play()
	else:
		CutsceneFlow.play(self,sequence)
