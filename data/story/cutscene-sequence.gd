@tool
class_name CutsceneSequence extends Resource
@export var sequence_id: String = ""
@export_file("*.dtl") var timeline_path: String = ""
@export_file("*.tres") var style_path: String = "res://dialogue/styles/story-style.tres"
@export var skippable: bool = false
@export var completion_signal: String = ""
@export var combat_after: bool = false
@export var phone_after: bool = false
@export var grant_spell: SpellData
@export_multiline var recap: String = ""
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if sequence_id.is_empty() or sequence_id.length() > 200 or completion_signal.is_empty() or completion_signal.length() > 256: errors.append("Cutscene needs bounded stable identity and completion signal")
	if not ResourceLoader.exists(timeline_path) or not load(timeline_path) is DialogicTimeline: errors.append("Cutscene needs an authored Dialogic timeline")
	if not style_path.is_empty() and (not ResourceLoader.exists(style_path) or not load(style_path) is DialogicStyle): errors.append("Invalid cutscene style")
	return errors
