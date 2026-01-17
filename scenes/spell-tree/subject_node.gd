# SubjectNode.gd
extends Button
class_name SubjectNode

signal selected(subject: subjectData)

var subject_data: subjectData

func setup(data: subjectData):
	subject_data = data
	text = data.subject_name  # show the name on the button

func _pressed():
	emit_signal("selected", subject_data)
