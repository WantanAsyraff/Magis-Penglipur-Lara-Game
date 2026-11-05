class_name StoryState extends RefCounted
enum Lifecycle { UNINITIALIZED, INITIALIZING, READY, RESTORING }
var lifecycle: Lifecycle = Lifecycle.UNINITIALIZED
var arc_id: StringName
var chapter_id: StringName
var stage_id: StringName
var objective_id: StringName
var objective_text: String = ""
var receipts: Dictionary = {}
var choices: Dictionary = {}
var action_receipts: Dictionary = {}
var dialogue_receipts: Dictionary = {}
var _transient: Dictionary = {}
func clear() -> void:
 lifecycle = Lifecycle.UNINITIALIZED
 arc_id = &""
 chapter_id = &""
 stage_id = &""
 objective_id = &""
 objective_text = ""
 receipts.clear()
 choices.clear()
 action_receipts.clear()
 dialogue_receipts.clear()
 _transient.clear()
func read_transient(id: StringName, fallback: Variant) -> Variant:
 return _transient.get(id, fallback)
func write_transient(id: StringName, value: Variant) -> void:
 _transient[id] = value
