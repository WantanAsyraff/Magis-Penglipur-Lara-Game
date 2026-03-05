class_name SubjectPanel extends Control
signal spells_learned(spells: Array[SpellData])

@onready var fieldOfStudy = %FieldOfStudyLabel
@onready var co = %TheorecticalFoundationLabel
@onready var coDesc = %CourseDescriptionLabel
@onready var casterNoteTitle = %CasterNoteTitleLabel
@onready var casterNote = %CasterNoteLabel
@onready var spellList = %SpellListLabel
@onready var spell = %SpellLabel

@export var subject_data: subjectData

func _process(delta: float) -> void:
	refresh_ui()

func refresh_ui():
	fieldOfStudy.text = subject_data.field_of_study
	co.text = subject_data.theoretical_foundation
	coDesc.text = subject_data.field_of_study + "\n\n" + subject_data.theoretical_foundation
	casterNote.text = subject_data.casters_notes
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
	Player_Global_Data.add_spells(subject_data.contained_spells)
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	_on_learn_button_pressed()
