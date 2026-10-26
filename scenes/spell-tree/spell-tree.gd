extends Control
class_name SpellTreeView

@onready var container = %SpellPath
@onready var field_label: Label = %FieldLabel

const SUBJECT_NODE_SCENE = preload("res://scenes/spell-tree/subject-node.tscn")
const SUBJECT_PANEL_SCENE = preload("res://scenes/spell-tree/subject-panel.tscn")

@export var course_data: CourseData
@export_group("Lock Visuals")
@export var locked_modulate: Color = Color(1, 1, 1, 0.4)
@export var lock_suffix: String = " 🔒"

const H_SPACING = 1000
const V_SPACING = 280

# -------------------------
# COST FORMULA
# -------------------------
const BASE_COST: int = 30
const SPELL_COUNT_WEIGHT: float = 0.25
const COMPREHENSION_MULTIPLIER: Dictionary = {
	"Novice": 1.0,
	"Intermediate": 1.5,
	"Advanced": 2.25,
	"Expert": 3.5
}

func get_subject_cost(data: subjectData) -> int:
	return Player_Global_Data.get_subject_cost(data)

func can_afford_subject(data: subjectData) -> bool:
	return Player_Global_Data.player_exp >= get_subject_cost(data)

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	add_to_group("spell_tree_view")
	Player_Global_Data.progression_changed.connect(_refresh_lock_states)
	if course_data:
		field_label.text = course_data.course_name
		build_spell_field()

# -------------------------
# BUILD
# -------------------------
func build_spell_field() -> void:
	for child in container.get_children():
		child.queue_free()
	container.nodes_map.clear()

	var subjects_dict = {}
	for s in course_data.subjects:
		subjects_dict[s.subject_id] = s

	var layers = {}
	for s in course_data.subjects:
		var d = _get_depth(s, subjects_dict)
		if not layers.has(d): layers[d] = []
		layers[d].append(s)

	for depth in layers.keys():
		var layer_subjects = layers[depth]
		for i in range(layer_subjects.size()):
			var data = layer_subjects[i]
			var node: SubjectNode = SUBJECT_NODE_SCENE.instantiate()
			container.add_child(node)
			node.setup(data, get_subject_cost(data))
			node.locked_modulate = locked_modulate
			node.lock_suffix = lock_suffix
			var is_locked := _is_subject_locked(data)
			node.set_locked(is_locked)
			node.selected.connect(_on_subject_selected)
			node.position = Vector2(50 + (depth * H_SPACING), 50 + (i * V_SPACING))
			container.nodes_map[data.subject_id] = node

	await get_tree().process_frame
	_update_scroll_limits()
	container.queue_redraw()

# -------------------------
# LOCK STATE
# -------------------------
func _is_subject_locked(data: subjectData) -> bool:
	for prereq_id in data.prerequisites:
		if not _player_has_completed_subject(prereq_id):
			return true
	return false

func _player_has_completed_subject(subject_id: String) -> bool:
	return Player_Global_Data.has_completed_subject(subject_id)

func _refresh_lock_states() -> void:
	for node in container.get_children():
		if node is SubjectNode:
			node.set_locked(_is_subject_locked(node.subject_data))

# -------------------------
# DEPTH
# -------------------------
func _get_depth(data: subjectData, dict: Dictionary, visiting: Array = []) -> int:
	if data.subject_id in visiting:
		push_warning("Circular subject prerequisite: " + data.subject_id)
		return 0
	visiting = visiting.duplicate()
	visiting.append(data.subject_id)
	if data.prerequisites.is_empty():
		return 0
	var max_d = 0
	for pid in data.prerequisites:
		if dict.has(pid):
			max_d = max(max_d, _get_depth(dict[pid], dict, visiting) + 1)
	return max_d

# -------------------------
# SCROLL
# -------------------------
func _update_scroll_limits() -> void:
	var max_v = Vector2.ZERO
	for node in container.get_children():
		if node is Control:
			max_v.x = max(max_v.x, node.position.x + node.size.x)
			max_v.y = max(max_v.y, node.position.y + node.size.y)
	container.custom_minimum_size = max_v + Vector2(100, 100)

# -------------------------
# SIGNALS
# -------------------------
func _on_subject_selected(subject: subjectData) -> void:
	if _is_subject_locked(subject):
		return
	var cost := get_subject_cost(subject)
	var panel = SUBJECT_PANEL_SCENE.instantiate()
	panel.subject_data = subject
	panel.xp_cost = cost
	panel.spells_learned.connect(_on_spells_learned)
	add_child(panel)

func _on_spells_learned(spells: Array[SpellData]) -> void:
	Player_Global_Data.add_spells(spells)
	_refresh_lock_states()

func _on_button_pressed() -> void:
	var prev := Player_Manager.previous_scene_path
	if prev == "":
		push_error("SpellTreeView: No previous scene stored in Player_Manager.")
		return
	if SceneManager:
		SceneManager.change_scene(prev)
	else:
		push_error("SpellTreeView: SceneManager not found!")
