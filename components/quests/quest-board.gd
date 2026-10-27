class_name QuestBoard extends Area2D
@export var npc_id: String = "bakau_field_researcher"
@export var display_name: String = "Technology & Science Field Researcher"
@export var region_id: StringName = &"bakau"
@export var database: QuestDatabase
var panel: QuestCatalogue
var canvas: CanvasLayer
var _was_paused: bool = false
var _nearby: Array[Node2D] = []
var dialogic: DialogicComponent
func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 140
	collision.shape = shape
	add_child(collision)
	var label := Label.new()
	label.name = "InteractLabel"
	label.position = Vector2(-120, -100)
	label.text = display_name + "\nE: quest board"
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	dialogic = DialogicComponent.new()
	add_child(dialogic)
	body_entered.connect(func(body):
		if body.is_in_group("player") and body not in _nearby: _nearby.append(body))
	body_exited.connect(func(body): _nearby.erase(body))
	var detection := DetectionComponent.new()
	detection.interacted.connect(open)
	add_child(detection)
	queue_redraw()
func open() -> void:
	if is_instance_valid(panel) or Dialogic.current_timeline != null or QuestOfferDialog.is_open() or not QuestManager.authoritative(): return
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.NPC_INTERACTED, npc_id))
	_was_paused = get_tree().paused
	canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	panel = load("res://scenes/ui/quest-ui/quest-catalogue.tscn").instantiate()
	panel.allow_offers = true
	panel.offer_source = self
	panel.embedded = true
	panel.hand_in_npc_id = npc_id
	panel.region_filter = region_id
	panel.dialogic = dialogic
	if database:
		for quest in database.quests: panel.allowed_quest_ids.append(quest.quest_id)
	canvas.add_child(panel)
	panel.close_requested.connect(close)
	get_tree().paused = true
func close() -> void:
	if is_instance_valid(canvas): canvas.queue_free()
	panel = null
	get_tree().paused = _was_paused
func _exit_tree() -> void:
	if is_instance_valid(panel): get_tree().paused = _was_paused
func _draw() -> void:
	draw_rect(Rect2(-42, -45, 84, 90), Color(.25, .35, .43))
	draw_rect(Rect2(-34, -36, 68, 65), Color(.75, .81, .7))
	for y in [-25, -10, 5, 20]: draw_line(Vector2(-23, y), Vector2(23, y), Color(.15, .2, .3), 3)
