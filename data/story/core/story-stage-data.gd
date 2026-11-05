class_name StoryStageData extends Resource
@export_group("Identity")
@export var stage_id: StringName
@export var display_name: String
@export_group("Narrative")
@export_multiline var description: String
@export_multiline var objective_hint: String
@export_group("Transitions")
@export var transitions: Array[StoryTransitionData] = []
@export_group("Lifecycle")
@export var on_exit_actions: Array[StoryAction] = []
@export var on_enter_actions: Array[StoryAction] = []
