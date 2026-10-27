class_name QuestOfferDialog extends Control
signal closed(decision: String)
static var current: QuestOfferDialog
var token: String = ""
var instance: QuestInstance
var identity: NPCPresentation
var source: Node
var dialogic: DialogicComponent
var accept_button: Button
var decline_button: Button
var _card: PanelContainer
var body: VBoxContainer
var _decision: String = "dismiss"
var _resolved := false
var _finished := false
var _previous_movement := true
var _scene: Node
static func is_open() -> bool:
	return is_instance_valid(current)
static func show_offer(instance_id: String, npc: String, origin: Node, presentation: NPCPresentation = null, dialogue: DialogicComponent = null) -> QuestOfferDialog:
	if is_open() or Dialogic.current_timeline != null or not is_instance_valid(origin) or not origin.is_inside_tree(): return null
	var manager := GameplayEvent.service("QuestManager")
	var receipt: String = manager.call("present_offer", instance_id, npc, presentation)
	if receipt.is_empty(): return null
	var panel: QuestOfferDialog = load("res://scenes/ui/quest-ui/quest-offer-dialog.tscn").instantiate()
	panel.token = receipt
	panel.instance = manager.call("get_instance", instance_id)
	panel.identity = presentation if presentation else NPCPresentation.resolve(npc)
	panel.source = origin
	panel.dialogic = dialogue
	var canvas := CanvasLayer.new()
	canvas.layer = 40
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	origin.get_tree().root.add_child(canvas)
	canvas.add_child(panel)
	return panel
func _ready() -> void:
	current = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_previous_movement = Player_Global_Data.p_moveable
	Player_Global_Data.p_moveable = false
	_scene = get_tree().current_scene
	theme = QuestWidgets.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.02, .04, .08, .94)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_card = PanelContainer.new()
	var card_style := QuestWidgets.style(Color("111d30"), 16)
	card_style.border_color = Color("596a83")
	card_style.set_border_width_all(2)
	_card.add_theme_stylebox_override("panel", card_style)
	add_child(_card)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 24)
	_card.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	header.add_child(QuestWidgets.avatar(identity, 80))
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(QuestWidgets.label(identity.display_name, 26))
	heading.add_child(QuestWidgets.label(String(instance.quest_data.region_id).capitalize() + " • " + QuestData.QuestType.keys()[instance.quest_data.type].capitalize(), 16, QuestWidgets.MUTED))
	header.add_child(heading)
	header.add_child(QuestWidgets.button("Close", func(): decide("dismiss")))
	layout.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	scroll.add_child(body)
	body.add_child(QuestWidgets.label(instance.quest_data.title, 30))
	body.add_child(QuestWidgets.label(identity.offer_dialogue if not identity.offer_dialogue.is_empty() else instance.quest_data.dialogue_offer, 21, Color("b9d8eb")))
	body.add_child(QuestWidgets.label(instance.quest_data.description))
	body.add_child(QuestWidgets.card(instance.quest_data, instance))
	if not instance.quest_data.prerequisite_quest_ids.is_empty(): body.add_child(QuestWidgets.label("Prerequisites: " + ", ".join(instance.quest_data.prerequisite_quest_ids), 15))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	decline_button = QuestWidgets.button("DECLINE", func(): decide("decline"))
	accept_button = QuestWidgets.button("ACCEPT QUEST", func(): decide("accept"))
	accept_button.add_theme_stylebox_override("normal", QuestWidgets.style(Color("286253")))
	for button in [decline_button, accept_button]: button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; footer.add_child(button)
	layout.add_child(footer)
	resized.connect(_fit)
	_fit.call_deferred()
	decline_button.grab_focus()
	if is_instance_valid(source): source.tree_exiting.connect(func(): decide("dismiss"), CONNECT_ONE_SHOT)
func decide(decision: String) -> void:
	if _resolved: return
	if decision != "dismiss" and get_tree().paused: return
	if not QuestManager.decide_offer(token, decision):
		if decision != "dismiss": return
	_resolved = true
	_decision = decision
	accept_button.disabled = true
	decline_button.disabled = true
	if decision != "dismiss":
		var reaction: String = instance.quest_data.dialogue_accepted if decision == "accept" else instance.quest_data.dialogue_declined
		if reaction.is_empty(): reaction = identity.accepted if decision == "accept" else identity.declined
		if is_instance_valid(dialogic) and dialogic.use_dialogic:
			hide()
			await dialogic.start_direct_text(reaction, identity.npc_id, identity.dialogue_identity)
	finish(decision)
func finish(decision: String) -> void:
	if _finished: return
	_finished = true
	if current == self: current = null
	Player_Global_Data.p_moveable = _previous_movement
	closed.emit(decision)
	var canvas := get_parent()
	queue_free()
	if canvas is CanvasLayer: canvas.queue_free()
func _process(_delta: float) -> void:
	if not _resolved and not QuestManager.live_offers.has(token):
		_resolved = true
		finish("dismiss")
		return
	if _resolved and not _finished and (not is_instance_valid(source) or source.is_queued_for_deletion() or _scene != get_tree().current_scene):
		if is_instance_valid(dialogic): dialogic.close()
		finish("dismiss")
		return
	if not _resolved and (_scene != get_tree().current_scene or get_tree().paused or not is_instance_valid(source) or source.is_queued_for_deletion()): decide("dismiss")
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _resolved:
			if is_instance_valid(dialogic): dialogic.close()
			finish(_decision)
		else: decide("dismiss")
		get_viewport().set_input_as_handled()
func _exit_tree() -> void:
	if not _resolved: QuestManager.decide_offer(token, "dismiss")
	if current == self: current = null
	Player_Global_Data.p_moveable = _previous_movement

func _fit() -> void:
	if not is_instance_valid(_card): return
	_card.size = Vector2(minf(size.x - 32, 920), minf(size.y - 32, 820))
	_card.position = (size - _card.size)/2
