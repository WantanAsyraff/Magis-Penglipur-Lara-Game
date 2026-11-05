class_name StorySubjectCondition extends StoryCondition
@export var subject_id: String = ""
@export var must_be_completed := true
func validate(_registry: StoryRegistry) -> PackedStringArray:
	return PackedStringArray(["Subject ID is required"]) if subject_id.is_empty() else PackedStringArray()
func evaluate(_context: StoryContext) -> bool:
	return not subject_id.is_empty() and Player_Global_Data.has_completed_subject(subject_id) == must_be_completed
