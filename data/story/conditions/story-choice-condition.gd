class_name StoryChoiceCondition extends StoryCondition
@export var choice: StoryChoiceData
@export var option_id: StringName
func validate(registry: StoryRegistry) -> PackedStringArray:
	if choice == null or registry.get_choice(choice.choice_id) != choice: return PackedStringArray(["A registered choice is required"])
	for option in choice.options:
		if option != null and option.option_id == option_id: return PackedStringArray()
	return PackedStringArray(["Option is not defined for this choice"])
func evaluate(context: StoryContext) -> bool:
	return validate(context.registry).is_empty() and context.state.choices.get(choice.choice_id, &"") == option_id
