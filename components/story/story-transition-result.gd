class_name StoryTransitionResult extends RefCounted
enum Status { AVAILABLE, BLOCKED, COMPLETED, FAILED }
var status: Status
var reason: String
var transition_id: StringName
func _init(id: StringName = &"", s: Status = Status.BLOCKED, why: String = "") -> void:
 transition_id = id
 status = s
 reason = why
