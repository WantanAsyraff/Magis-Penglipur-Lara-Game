class_name StoryStageCondition extends StoryCondition
@export var stage_id: StringName
@export var equal: bool = true
func validate(registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Unknown stage: " + String(stage_id)]) if registry.get_stage(stage_id) == null else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
 return validate(context.registry).is_empty() and context.state.lifecycle == StoryState.Lifecycle.READY and (context.stage_id() == stage_id) == equal
