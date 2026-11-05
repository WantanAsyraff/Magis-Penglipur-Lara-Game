class_name StoryDialogueVariant extends Resource
@export_group("Identity")
@export var variant_id: StringName
@export var priority: int = 0
@export var conditions: Array[StoryCondition] = []
@export_group("Dialogue")
@export var timeline: DialogicTimeline
@export_multiline var direct_text: String
@export var dialogue_identity: String = ""
@export_group("Completion")
@export var once_only := false
func valid() -> bool:
 return not variant_id.is_empty() and String(variant_id).length() <= 128 and String(variant_id) == String(variant_id).to_lower() and (timeline != null or not direct_text.is_empty()) and not (timeline != null and not direct_text.is_empty())
