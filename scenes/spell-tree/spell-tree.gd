extends Control
class_name SpellTreeView

@onready var container = %SpellPath  # This must be a plain Control

const SUBJECT_NODE_SCENE = preload("res://scenes/spell-tree/subject_node.tscn")
const SUBJECT_PANEL_SCENE = preload("res://scenes/spell-tree/subject-panel.tscn")

@export var next_scene_id: String
@export var spawn_marker_override: String = ""
@export var course_data: CourseData

var nodes := []

func _ready():
	if course_data:
		build_spell_field()

func _process(_delta):
	queue_redraw()

func build_spell_field():
	# Clear old nodes
	for child in container.get_children():
		child.queue_free()
	nodes.clear()
	
	var spacing_y = 150
	var start_x = 200
	var start_y = 50
	
	for i in range(course_data.subjects.size()):
		var subject = course_data.subjects[i]
		var node = SUBJECT_NODE_SCENE.instantiate()
		node.setup(subject)
		node.selected.connect(_on_subject_selected)
		container.add_child(node)
		nodes.append(node)
		
		# Manual vertical layout
		node.position = Vector2(start_x, start_y + i * spacing_y)
	
	# Tell Godot to redraw lines
	queue_redraw()

func _draw():
	if nodes.size() < 2:
		return
	
	for i in range(nodes.size() - 1):
		var a = nodes[i]
		var b = nodes[i + 1]
		
		# Bottom middle of current button
		var start_global = a.global_position + Vector2(a.size.x / 2, a.size.y)
		# Top middle of next button
		var end_global   = b.global_position + Vector2(b.size.x / 2, 0)
		
		# Convert to local space
		var start_local = start_global - global_position
		var end_local   = end_global - global_position
		
		draw_line(start_local, end_local, Color.WHITE, 2)

func _on_subject_selected(subject: subjectData):
	var panel = SUBJECT_PANEL_SCENE.instantiate()
	panel.subject_data = subject
	# Connect panel → player
	panel.spells_learned.connect(_on_spells_learned)
	add_child(panel)

func _on_spells_learned(spells: Array[SpellData]):
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.add_spells(spells)

func _on_button_pressed() -> void: # back button
	var scene_data = Scene_Registry.get_scene(next_scene_id)
	if not scene_data:
		push_error("Scene not found: " + next_scene_id)
		return
	
	# Use override or default from SceneData
	var spawn_marker = spawn_marker_override if spawn_marker_override else scene_data.default_spawn_marker
	
	if spawn_marker:
		Player_Manager.set_meta("next_spawn_marker", spawn_marker)
	
	SceneManager.change_scene(scene_data.scene.resource_path)
