class_name SubjectPanel extends Control
signal spells_learned(spells: Array[SpellData])

@onready var title = %SubjectLabel
@onready var co = %CourseOutlineLabel
@onready var coDesc = %CourseDescriptionLabel
@onready var spellList = %SpellListLabel
@onready var spell = %SpellLabel

@export var subject_data: subjectData

func _process(delta: float) -> void:
	refresh_ui()

func refresh_ui():
	title.text = subject_data.subject_name
	coDesc.text = subject_data.subject_description
	display_spells()

func display_spells():
	if subject_data.contained_spells.is_empty():
		spell.text = "No spells"
		return
	var result := ""
	for s in subject_data.contained_spells:
		result += "- %s\n" % s.spell_name
	spell.text = result

func _on_learn_button_pressed():
	emit_signal("spells_learned", subject_data.contained_spells)
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	_on_learn_button_pressed()
