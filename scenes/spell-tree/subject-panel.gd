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
@onready var spell_cost_label = %SpellCostLabel

@export var subject_data: subjectData
var xp_cost: int = 0
var course_data: CourseData

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	Player_Global_Data.progression_changed.connect(refresh_ui)
	refresh_ui()

# -------------------------
# UI
# -------------------------
func refresh_ui() -> void:
	fieldOfStudy.text = subject_data.field_of_study
	co.text = subject_data.theoretical_foundation
	coDesc.text = subject_data.field_of_study + "\n\n" + subject_data.theoretical_foundation
	casterNote.text = subject_data.casters_notes
	display_spells()
	_update_cost_label()
	_update_prereq_state()

func display_spells() -> void:
	if subject_data.contained_spells.is_empty():
		spell.text = "No spells"
		return
	var result := ""
	for s in subject_data.contained_spells:
		result += "- %s\n" % s.spell_name
	spell.text = result

func _update_cost_label() -> void:
	if not spell_cost_label:
		return
	var current_exp: int = Player_Global_Data.player_exp
	if current_exp >= xp_cost:
		spell_cost_label.text = "Cost: %d XP  (You have: %d)" % [xp_cost, current_exp]
		spell_cost_label.modulate = Color.WHITE
	else:
		spell_cost_label.text = "Cost: %d XP  (You have: %d — not enough)" % [xp_cost, current_exp]
		spell_cost_label.modulate = Color(1.0, 0.4, 0.4)

# -------------------------
# PREREQ / LOCK
# -------------------------
func _get_missing_prerequisites() -> Array[String]:
	var missing: Array[String] = []
	for prereq_id in subject_data.prerequisites:
		if not _player_has_completed_subject(prereq_id):
			missing.append(prereq_id)
	return missing

func _player_has_completed_subject(subject_id: String) -> bool:
	return Player_Global_Data.has_completed_subject(subject_id)

func _get_spells_for_subject(subject_id: String) -> Array[SpellData]:
	var tree_view = get_tree().get_first_node_in_group("spell_tree_view")
	if not tree_view or not tree_view.course_data:
		return []
	for s in tree_view.course_data.subjects:
		if s.subject_id == subject_id:
			return s.contained_spells
	return []

func _update_prereq_state() -> void:
	var missing := _get_missing_prerequisites()
	var prereqs_locked := not missing.is_empty()
	var cant_afford := Player_Global_Data.player_exp < xp_cost

	if learn_button:
		learn_button.disabled = not Player_Global_Data.can_purchase_subject(subject_data, course_data)

	if prereq_label:
		if prereqs_locked:
			prereq_label.text = "Locked — complete first: " + ", ".join(missing)
			prereq_label.visible = true
		else:
			prereq_label.visible = false

# -------------------------
# BUTTONS
# -------------------------
func _on_learn_button_pressed() -> void:
	if not Player_Global_Data.purchase_subject(subject_data, course_data):
		return
	emit_signal("spells_learned", subject_data.contained_spells)
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_confirm_button_pressed() -> void:
	_on_learn_button_pressed()
