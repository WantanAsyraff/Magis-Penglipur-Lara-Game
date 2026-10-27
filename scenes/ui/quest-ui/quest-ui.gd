class_name QuestUI extends Control
signal back_pressed
var selected_contact: String = ""
var _layout: VBoxContainer
var _history: VBoxContainer
var _scroll: ScrollContainer
var _queued := false
var rendered_bubbles: Array[Control] = []
var quest_cards: Dictionary = {}
var contact_rows: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = QuestWidgets.theme()
	QuestManager.quests_changed.connect(_schedule)
	_refresh()
func _schedule() -> void:
	if _queued: return
	_queued = true
	_refresh.call_deferred()
func _refresh() -> void:
	_queued = false
	for child in get_children(): remove_child(child); child.queue_free()
	rendered_bubbles.clear()
	quest_cards.clear()
	contact_rows.clear()
	var background := ColorRect.new()
	background.color = Color("0f192a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 12)
	add_child(margin)
	_layout = VBoxContainer.new()
	_layout.add_theme_constant_override("separation", 12)
	margin.add_child(_layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.add_child(QuestWidgets.button("‹", _back))
	if selected_contact.is_empty():
		header.add_child(QuestWidgets.label("Quest messages", 24))
	else:
		var identity := NPCPresentation.for_conversation(QuestManager.conversations.contacts[selected_contact])
		header.add_child(QuestWidgets.avatar(identity, 44))
		header.add_child(QuestWidgets.label(identity.display_name, 20))
	_layout.add_child(header)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_child(_scroll)
	_history = VBoxContainer.new()
	_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_history.add_theme_constant_override("separation", 12)
	_scroll.add_child(_history)
	if selected_contact.is_empty(): _show_contacts()
	else: _show_history()
func _show_contacts() -> void:
	var contacts: Array = QuestManager.conversations.contacts.values()
	contacts.sort_custom(func(a, b): return int(a.entries.back().sequence) > int(b.entries.back().sequence))
	if contacts.is_empty():
		_history.add_child(QuestWidgets.label("Your quest contacts will appear here after you speak with a quest giver.", 18, QuestWidgets.MUTED))
	for contact in contacts:
		var identity := NPCPresentation.for_conversation(contact)
		var button := QuestWidgets.contact_preview(identity, contact, _contact_status(contact), _select.bind(contact.npc_id))
		_history.add_child(button)
		contact_rows[contact.npc_id] = button
func _contact_status(contact: QuestConversation) -> String:
	for i in range(contact.entries.size()-1, -1, -1):
		var kind: String = contact.entries[i].event_type
		if kind in ["PLAYER_DECLINED", "PLAYER_ACCEPTED", "QUEST_READY_FOR_HAND_IN", "QUEST_COMPLETED", "QUEST_EXPIRED", "OFFER_PRESENTED"]:
			return {"PLAYER_DECLINED": "Declined", "PLAYER_ACCEPTED": "Accepted", "QUEST_READY_FOR_HAND_IN": "Ready to Submit", "QUEST_COMPLETED": "Completed", "QUEST_EXPIRED": "Expired", "OFFER_PRESENTED": "Offered"}[kind]
	return "Quest contact"
func _select(id: String) -> void:
	selected_contact = id
	QuestManager.mark_conversation_read(id)
	_refresh()
func _show_history() -> void:
	var contact: QuestConversation = QuestManager.conversations.contacts.get(selected_contact)
	if contact == null: selected_contact = ""; _show_contacts(); return
	for entry in contact.entries:
		var bubble := QuestWidgets.bubble(entry)
		rendered_bubbles.append(bubble)
		_history.add_child(bubble)
	for id in contact.quest_ids:
		var data: QuestData = QuestManager.registry.quests.get(id)
		if not data: continue
		var current: QuestInstance
		for instance in QuestManager._active_instances.values():
			if instance.quest_data.quest_id == id and instance.assigned_npc_id == selected_contact and instance.owner_id == QuestManager.active_owner_id: current = instance
		var status_override := ""
		if current == null or current.status == QuestInstance.Status.AVAILABLE:
			for i in range(contact.entries.size()-1, -1, -1):
				var entry: Dictionary = contact.entries[i]
				if entry.quest_id != id: continue
				if entry.event_type == "PLAYER_DECLINED": status_override = "Declined · Reoffer available in person"; break
				if entry.event_type == "OFFER_DISMISSED": status_override = "Dismissed · No decision"; break
				if entry.event_type == "OFFER_PRESENTED": break
		var card := QuestWidgets.card(data, current, status_override)
		quest_cards[id] = card
		_history.add_child(card)
	QuestManager.mark_conversation_read(selected_contact)
	_scroll_to_end.call_deferred()
func _scroll_to_end() -> void:
	if is_instance_valid(_scroll): _scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
func _back() -> void:
	if not selected_contact.is_empty(): selected_contact = ""; _refresh()
	else: back_pressed.emit()
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
