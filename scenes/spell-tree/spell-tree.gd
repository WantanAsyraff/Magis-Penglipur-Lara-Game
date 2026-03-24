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

func _ready() -> void:
	add_to_group("spell_tree_view")
	if course_data:
		field_label.text = course_data.course_name
		build_spell_field()

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
			node.setup(data)

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

func _is_subject_locked(data: subjectData) -> bool:
	for prereq_id in data.prerequisites:
		if not _player_has_completed_subject(prereq_id):
			return true
	return false

func _player_has_completed_subject(subject_id: String) -> bool:
	for s in course_data.subjects:
		if s.subject_id == subject_id:
			for spell in s.contained_spells:
				if Player_Global_Data.learned_spells.has(spell):
					return true
			return false
	return false

func _get_depth(data: subjectData, dict: Dictionary) -> int:
	if data.prerequisites.is_empty():
		return 0
	var max_d = 0
	for pid in data.prerequisites:
		if dict.has(pid):
			max_d = max(max_d, _get_depth(dict[pid], dict) + 1)
	return max_d

func _update_scroll_limits() -> void:
	var max_v = Vector2.ZERO
	for node in container.get_children():
		if node is Control:
			max_v.x = max(max_v.x, node.position.x + node.size.x)
			max_v.y = max(max_v.y, node.position.y + node.size.y)
	container.custom_minimum_size = max_v + Vector2(100, 100)

func _on_subject_selected(subject: subjectData) -> void:
	var panel = SUBJECT_PANEL_SCENE.instantiate()
	panel.subject_data = subject
	panel.spells_learned.connect(_on_spells_learned)
	add_child(panel)

func _on_spells_learned(spells: Array[SpellData]) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.add_spells(spells)
	_refresh_lock_states()

func _refresh_lock_states() -> void:
	for node in container.get_children():
		if node is SubjectNode:
			node.set_locked(_is_subject_locked(node.subject_data))

func _on_button_pressed() -> void:
	var prev := Player_Manager.previous_scene_path
	if prev == "":
		push_error("SpellTreeView: No previous scene stored in Player_Manager.")
		return
	if SceneManager:
		SceneManager.change_scene(prev)
	else:
		push_error("SpellTreeView: SceneManager not found!")
