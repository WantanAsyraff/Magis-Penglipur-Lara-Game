class_name QuestUI extends Control
signal close_requested
@export var allow_offers: bool = false
@export var embedded: bool = false
@export var hand_in_npc_id: String = ""
@export var region_filter: StringName = &""
var allowed_quest_ids: Array[String] = []
var selected_quest_id: String = ""
var _refresh_queued: bool = false
var _buttons: Dictionary = {}
var _instance: QuestInstance
var dialogic: DialogicComponent
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	QuestManager.quests_changed.connect(_schedule_refresh)
	_refresh()
func _schedule_refresh() -> void:
	if _refresh_queued: return
	_refresh_queued = true
	_refresh.call_deferred()
func _find_instance(id: String) -> QuestInstance:
	var result: QuestInstance
	for instance in QuestManager._active_instances.values():
		if instance.owner_id == QuestManager.active_owner_id and instance.status not in [QuestInstance.Status.EXPIRED, QuestInstance.Status.CANCELLED] and instance.quest_data.quest_id == id: result = instance
	return result
func _refresh(_unused: QuestInstance = null) -> void:
	_refresh_queued = false
	for child in %ChatLogsVBox.get_children():
		%ChatLogsVBox.remove_child(child)
		child.queue_free()
	_buttons.clear()
	var group: StringName = &""
	for data in QuestManager.registry.quests.values():
		if region_filter != &"" and data.region_id != region_filter: continue
		if not allowed_quest_ids.is_empty() and data.quest_id not in allowed_quest_ids: continue
		if data.region_id != group:
			group = data.region_id
			var heading := Label.new()
			heading.text = ("Technology & Science" if data.faculty == QuestData.Faculty.TECHNOLOGY_SCIENCE else String(QuestData.Faculty.keys()[data.faculty]).capitalize()) + " / " + String(data.region_id).capitalize()
			heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			heading.add_theme_font_size_override("font_size", 18)
			%ChatLogsVBox.add_child(heading)
		var instance := _find_instance(data.quest_id)
		var state := "Completed" if QuestManager.is_quest_complete(data.quest_id) else "Locked" if not QuestManager._prerequisites_met(data) else "Available"
		if instance: state = QuestInstance.Status.keys()[instance.status].capitalize()
		var button := Button.new()
		button.text = data.title + "\n" + state + (" • Tracked" if instance and instance.instance_id == QuestManager.selected_instance_id else "")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(240, 64)
		button.pressed.connect(_select.bind(data.quest_id))
		%ChatLogsVBox.add_child(button)
		_buttons[data.quest_id] = button
	if selected_quest_id.is_empty() or not _buttons.has(selected_quest_id):
		var tracked := QuestManager.get_instance(QuestManager.selected_instance_id)
		selected_quest_id = tracked.quest_data.quest_id if tracked and _buttons.has(tracked.quest_data.quest_id) else String(_buttons.keys()[0]) if not _buttons.is_empty() else ""
	_show_details()
func _select(id: String) -> void:
	selected_quest_id = id
	_show_details()
func _show_details() -> void:
	var data: QuestData = QuestManager.registry.quests.get(selected_quest_id)
	if data == null: return
	_instance = _find_instance(data.quest_id)
	%QuestNameLabel.text = data.title
	%QuestFlavourLabel.text = data.description
	var lines: Array[String] = []
	for obj in data.objectives:
		var count := int(_instance.objective_progress.get(obj.objective_id, 0)) if _instance else 0
		var text := "%s: %d / %d" % [obj.description, count, obj.required_amount]
		if obj.is_optional: text += " (optional)"
		if _instance and not _instance.eligible(obj): text += " — Complete earlier objective first"
		if obj.type == QuestObjectiveData.ObjectiveType.COLLECT_ITEM:
			text += "\n" + ["Acquire after acceptance", "Currently held", "Deliver at hand-in"][obj.collection_mode]
			if obj.targets().size() > 1: text += " • Any combination"
		lines.append(text)
	%ObjectivesLabel.text = "\n\n".join(lines)
	var rewards: Array[String] = ["%d XP" % data.reward_xp]
	if data.reward_currency > 0: rewards.append("RM %d" % data.reward_currency)
	for loot in data.reward_items: rewards.append("%d × %s" % [loot.min_quantity, loot.item.item_name])
	for spell in data.reward_spells: rewards.append("Learn " + spell.spell_name)
	%RewardsLabel.text = "Rewards\n" + "\n".join(rewards)
	var required: Array[String] = []
	for id in data.prerequisite_quest_ids:
		required.append(QuestManager.registry.quests[id].title + (" ✓" if QuestManager.is_quest_complete(id) else " — incomplete"))
	%PrerequisitesLabel.text = "Prerequisites: " + (", ".join(required) if not required.is_empty() else "None")
	var ready := _instance and _instance.status == QuestInstance.Status.COMPLETE
	%StatusLabel.text = "Completed" if QuestManager.is_quest_complete(data.quest_id) else "Ready for hand-in" if ready else "In progress" if _instance and _instance.status == QuestInstance.Status.ACTIVE else "Locked" if not QuestManager._prerequisites_met(data) else "Available from a quest giver"
	if _instance and not _instance.pending_claim.is_empty(): %StatusLabel.text += "\n" + _instance.pending_claim
	%AcceptButton.visible = allow_offers and (not _instance or _instance.status == QuestInstance.Status.AVAILABLE) and not QuestManager.is_quest_complete(data.quest_id)
	%AcceptButton.disabled = not QuestManager._prerequisites_met(data)
	%ClaimButton.visible = allow_offers and ready
	%TrackButton.disabled = _instance == null or _instance.status not in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]
	%DiscussButton.visible = dialogic != null
func _accept() -> void:
	var instance := QuestManager.offer_quest(selected_quest_id, hand_in_npc_id)
	if instance:
		QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.NPC_INTERACTED, hand_in_npc_id))
		QuestManager.accept_quest(instance.instance_id)
func _claim() -> void:
	if _instance: QuestManager.try_hand_off(_instance.instance_id, hand_in_npc_id)
	_show_details()
func _track() -> void:
	if _instance: QuestManager.select_quest(_instance.instance_id)
func _discuss() -> void:
	if dialogic == null or dialogic.is_open(): return
	var data: QuestData = QuestManager.registry.quests[selected_quest_id]
	var text := data.dialogue_complete if QuestManager.is_quest_complete(data.quest_id) else data.dialogue_incomplete if _instance and _instance.status == QuestInstance.Status.ACTIVE else data.dialogue_offer
	var was_paused := get_tree().paused
	get_tree().paused = false
	await dialogic.start_direct_text(text, hand_in_npc_id)
	if is_inside_tree() and embedded: get_tree().paused = was_paused
func _on_back_button_pressed() -> void:
	if embedded: close_requested.emit(); return
	if not Player_Global_Data.previous_scene.is_empty(): SceneManager.change_scene(Player_Global_Data.previous_scene)
	else: hide()
	Player_Global_Data.p_moveable = true
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): _on_back_button_pressed(); get_viewport().set_input_as_handled()
