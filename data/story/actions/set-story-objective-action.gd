class_name SetStoryObjectiveAction extends StoryAction
@export var objective_id: StringName
@export_multiline var display_text: String
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Objective ID/text required"]) if objective_id.is_empty() or display_text.is_empty() else PackedStringArray()
func execute(context: StoryActionContext) -> Result:
 if not validate(context.registry).is_empty(): return Result.REJECTED
 context.director.state.objective_id = objective_id
 context.director.state.objective_text = display_text
 return Result.SUCCESS
