class_name StoryChapterData extends Resource
@export_group("Identity")
@export var chapter_id: StringName
@export var chapter_name: String
@export_multiline var synopsis: String
@export_group("Stages")
@export var stages: Array[StoryStageData] = []
@export var initial_stage_id: StringName
