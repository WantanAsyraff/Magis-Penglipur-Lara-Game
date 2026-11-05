class_name StoryArcData extends Resource
@export_group("Identity")
@export var arc_id: StringName
@export var display_name: String
@export_multiline var description: String
@export_group("Structure")
@export var chapters: Array[StoryChapterData] = []
@export var initial_chapter_id: StringName
