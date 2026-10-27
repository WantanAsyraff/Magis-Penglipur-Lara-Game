class_name QuestObjectiveGroup extends Resource
enum Policy { ALL, ANY }
@export var group_id: StringName = &""
@export var policy: Policy = Policy.ALL
@export var minimum_completed: int = 1
@export var is_optional: bool = false
