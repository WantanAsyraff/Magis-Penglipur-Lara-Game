class_name SubjectPanel extends Control

signal spells_learned(spells: Array[SpellData])

@onready var fieldOfStudy = %FieldOfStudyLabel
@onready var co = %TheorecticalFoundationLabel
@onready var coDesc = %CourseDescriptionLabel
@onready var casterNoteTitle = %CasterNoteTitleLabel
@onready var casterNote = %CasterNoteLabel
@onready var spellList = %SpellListLabel
@onready var spell = %SpellLabel
@onready var learn_button = %LearnButton
@onready var prereq_label = %PrereqLabel

@export var subject_data: subjectData

func _ready() -> void:
	refresh_ui()

func _process(delta: float) -> void:
	refresh_ui()

func refresh_ui() -> void:
	fieldOfStudy.text = subject_data.field_of_study
	co.text = subject_data.theoretical_foundation
	coDesc.text = subject_data.field_of_study + "\n\n" + subject_data.theoretical_foundation
	casterNote.text = subject_data.casters_notes
	display_spells()
	_update_prereq_state()

func display_spells() -> void:
	if subject_data.contained_spells.is_empty():
		spell.text = "No spells"
		return
	var result := ""
	for s in subject_data.contained_spells:
		result += "- %s\n" % s.spell_name
	spell.text = result

func _get_missing_prerequisites() -> Array[String]:
	var missing: Array[String] = []
	for prereq_id in subject_data.prerequisites:
		if not _player_has_completed_subject(prereq_id):
			missing.append(prereq_id)
	return missing

func _player_has_completed_subject(subject_id: String) -> bool:
	# A subject is considered complete if the player has learned
	# at least one spell from it. Adjust this logic if you track
	# completed subjects separately in Player_Global_Data.
	for spell_data in Player_Global_Data.learned_spells:
		for course_spell in _get_spells_for_subject(subject_id):
			if spell_data == course_spell:
				return true
	return false

func _get_spells_for_subject(subject_id: String) -> Array[SpellData]:
	# Walk the scene tree to find the SpellTreeView and look up the subject
	var tree_view = get_tree().get_first_node_in_group("spell_tree_view")
	if not tree_view or not tree_view.course_data:
		return []
	for s in tree_view.course_data.subjects:
		if s.subject_id == subject_id:
			return s.contained_spells
	return []

func _update_prereq_state() -> void:
	var missing := _get_missing_prerequisites()
	var locked := not missing.is_empty()

	if learn_button:
		learn_button.disabled = locked

	if prereq_label:
		if locked:
			var names := ", ".join(missing)
			prereq_label.text = "Locked — complete first: " + names
			prereq_label.visible = true
		else:
			prereq_label.visible = false

func _on_learn_button_pressed() -> void:
	if not _get_missing_prerequisites().is_empty():
		return
	Player_Global_Data.add_spells(subject_data.contained_spells)
	emit_signal("spells_learned", subject_data.contained_spells)
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	_on_learn_button_pressed()
