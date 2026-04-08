extends Button
class_name SubjectNode

signal selected(subject: subjectData)

var subject_data: subjectData
var _locked: bool = false

@export var locked_modulate: Color = Color(1, 1, 1, 0.4)
@export var lock_suffix: String = " 🔒"

func setup(data: subjectData, cost: int = 0) -> void:
	subject_data = data
	text = "%s\n%d XP" % [data.subject_name, cost]

func set_locked(is_locked: bool) -> void:
	_locked = is_locked
	disabled = is_locked
	if is_locked:
		text = subject_data.subject_name + lock_suffix
		modulate = locked_modulate
	else:
		text = subject_data.subject_name
		modulate = Color.WHITE

func _pressed() -> void:
	if _locked:
		return
	emit_signal("selected", subject_data)
