extends Control
class_name SpellTreeView

@onready var container = %SpellPath # This is the Control node with spell_path.gd
const SUBJECT_NODE_SCENE = preload("res://scenes/spell-tree/subject_node.tscn")
const SUBJECT_PANEL_SCENE = preload("res://scenes/spell-tree/subject-panel.tscn")

@export var course_data: CourseData
@export var next_scene_id: String

const H_SPACING = 300 # Width of each "tier"
const V_SPACING = 180 # Vertical gap between nodes

func _ready():
	if course_data:
		build_spell_field()

func build_spell_field():
	# 1. Cleanup
	for child in container.get_children():
		child.queue_free()
	container.nodes_map.clear()

	# 2. Build Data Map
	var subjects_dict = {}
	for s in course_data.subjects:
		subjects_dict[s.subject_id] = s

	# 3. Calculate Layers (Depth)
	var layers = {} # depth_int -> Array[SubjectData]
	for s in course_data.subjects:
		var d = _get_depth(s, subjects_dict)
		if not layers.has(d): layers[d] = []
		layers[d].append(s)

	# 4. Instantiate & Position
	for depth in layers.keys():
		var layer_subjects = layers[depth]
		for i in range(layer_subjects.size()):
			var data = layer_subjects[i]
			var node = SUBJECT_NODE_SCENE.instantiate()
			
			container.add_child(node)
			node.setup(data)
			node.selected.connect(_on_subject_selected)
			
			# Layout: X = depth, Y = index in layer
			node.position = Vector2(50 + (depth * H_SPACING), 50 + (i * V_SPACING))
			container.nodes_map[data.subject_id] = node

	# 5. Update Scroll Area & Redraw Lines
	await get_tree().process_frame
	_update_scroll_limits()
	container.queue_redraw()

func _get_depth(data: subjectData, dict: Dictionary) -> int:
	if data.prerequisites.is_empty():
		return 0
	var max_d = 0
	for pid in data.prerequisites:
		if dict.has(pid):
			max_d = max(max_d, _get_depth(dict[pid], dict) + 1)
	return max_d

func _update_scroll_limits():
	var max_v = Vector2.ZERO
	for node in container.get_children():
		if node is Control:
			max_v.x = max(max_v.x, node.position.x + node.size.x)
			max_v.y = max(max_v.y, node.position.y + node.size.y)
	container.custom_minimum_size = max_v + Vector2(100, 100)

# --- Keep your existing signal functions below ---
func _on_subject_selected(subject: subjectData):
	var panel = SUBJECT_PANEL_SCENE.instantiate()
	panel.subject_data = subject
	panel.spells_learned.connect(_on_spells_learned)
	add_child(panel)

func _on_spells_learned(spells: Array[SpellData]):
	var player := get_tree().get_first_node_in_group("player")
	if player: player.add_spells(spells)

func _on_button_pressed() -> void:
	print("--- Transition Attempt Started ---")
	print("Target ID: ", next_scene_id)
	
	if next_scene_id == "":
		push_error("FAILED: next_scene_id is empty in the Inspector!")
		return

	var scene_data = Scene_Registry.get_scene(next_scene_id)
	
	if not scene_data:
		push_error("FAILED: Scene_Registry could not find ID: " + next_scene_id)
		# Print all known IDs so you can see if there is a typo
		print("Available IDs: ", Scene_Registry.scenes.keys()) 
		return

	print("SUCCESS: Found path: ", scene_data.scene.resource_path)

	# Execute change
	if SceneManager:
		SceneManager.change_scene(scene_data.scene.resource_path)
	else:
		push_error("FAILED: SceneManager Autoload not found!")
