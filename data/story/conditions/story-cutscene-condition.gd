class_name StoryCutsceneCondition extends StoryCondition
@export var sequence_reference: CutsceneSequence
@export var must_be_completed: bool = true
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Missing or invalid CutsceneSequence"]) if sequence_reference == null or not sequence_reference.validate().is_empty() else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
 return validate(context.registry).is_empty() and context.is_cutscene_complete(sequence_reference) == must_be_completed
