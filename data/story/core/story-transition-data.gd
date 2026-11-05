class_name StoryTransitionData extends Resource
@export_group("Identity")
@export var transition_id: StringName
@export var display_name: String
@export_group("Destination")
@export var target_stage_id: StringName
@export_group("Requirements")
@export var conditions: Array[StoryCondition] = []
@export var required_event_type: GameplayEvent.Type = GameplayEvent.Type.WORLD_FLAG_CHANGED
@export var required_event_target: String = ""
@export var required_choice_id: StringName
@export var required_option_id: StringName
@export_group("Selection")
@export var priority: int = 0
@export var automatic: bool = true
@export_group("Execution")
@export var once_only: bool = true
@export var actions: Array[StoryAction] = []
