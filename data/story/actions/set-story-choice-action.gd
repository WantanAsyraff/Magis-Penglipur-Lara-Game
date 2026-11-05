class_name SetStoryChoiceAction extends StoryAction
@export var choice: StoryChoiceData
@export var selected_option_id: StringName
func validate(_registry: StoryRegistry) -> PackedStringArray:
 if choice == null or choice.choice_id.is_empty(): return PackedStringArray(["Choice definition missing"])
 for option in choice.options:
  if option != null and option.option_id == selected_option_id: return PackedStringArray()
 return PackedStringArray(["Choice option missing"])
func execute(context: StoryActionContext) -> Result:
 if not validate(context.registry).is_empty(): return Result.REJECTED
 # confirm_choice stages this value only for the duration of its validated branch request.
 return Result.NO_CHANGE if context.director.get_recorded_choice(choice.choice_id) == selected_option_id else Result.REJECTED
