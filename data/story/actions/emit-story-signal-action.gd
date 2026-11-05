class_name EmitStorySignalAction extends StoryAction
@export var event_id: StringName
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Story signal ID required"]) if event_id.is_empty() else PackedStringArray()
func execute(context: StoryActionContext) -> Result:
 if not validate(context.registry).is_empty(): return Result.REJECTED
 context.director.story_notification.emit(event_id)
 return Result.SUCCESS
