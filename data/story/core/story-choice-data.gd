class_name StoryChoiceData extends Resource
@export var choice_id: StringName
@export_multiline var prompt: String
@export var options: Array[StoryChoiceOptionData] = []
