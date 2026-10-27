class_name QuestWidgets extends RefCounted
const INK = Color("e9eff7")
const MUTED = Color("9daebf")
static func style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box
static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = load("res://assets/font/Bitter/static/Bitter-Regular.ttf")
	result.default_font_size = 17
	result.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		result.set_stylebox(state, "Button", style(Color("253950") if state == "normal" else Color("365471") if state in ["hover", "focus"] else Color("17263a")))
	return result
static func label(text: String, size: int = 17, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node
static func avatar(identity: NPCPresentation, dimension: int = 56) -> TextureRect:
	var node := TextureRect.new()
	node.texture = identity.resolved_portrait()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(dimension, dimension)
	return node
static func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 44
	node.pressed.connect(action)
	return node
static func rewards(data: QuestData) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	var entries: Array = [{"texture": load("res://assets/ui/quests/experience.svg"), "text": "%d XP" % data.reward_xp}]
	if data.reward_currency > 0: entries.append({"texture": load("res://assets/ui/quests/currency.svg"), "text": "RM%d" % data.reward_currency})
	for loot in data.reward_items: entries.append({"texture": loot.item.item_icon, "item": true, "text": "%d × %s" % [loot.min_quantity, loot.item.item_name]})
	for entry in entries:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.texture = entry.texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		chip.add_child(icon)
		var text := label(entry.text, 16)
		text.custom_minimum_size.x = 220 if entry.get("item", false) else 85
		chip.add_child(text)
		flow.add_child(chip)
	return flow
static func objective_text(data: QuestData, instance: QuestInstance = null) -> String:
	var lines: Array[String] = []
	for obj in data.objectives:
		lines.append("%s: %d / %d%s" % [obj.description, instance.objective_progress.get(obj.objective_id, 0) if instance else 0, obj.required_amount, " (optional)" if obj.is_optional else ""])
	return "\n".join(lines)
static func card(data: QuestData, instance: QuestInstance = null, status_override: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(Color("1c3042")))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	content.add_child(label(data.title, 20))
	content.add_child(label(objective_text(data, instance)))
	var status := "Offered"
	if instance:
		status = {0: "Offered", 1: "In Progress", 2: "Ready to Submit", 3: "Completed", 4: "Expired", 5: "Cancelled"}.get(instance.status, "")
	content.add_child(label(status_override if not status_override.is_empty() else status, 15, Color("83d2ba")))
	content.add_child(rewards(data))
	return panel
static func bubble(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var is_player: bool = entry.sender_type == "player"
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = .12
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(Color("295449") if is_player else Color("223348") if entry.sender_type == "npc" else Color("172337")))
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_child(label(entry.message_text))
	column.add_child(label("%s · #%d" % [entry.sender_type.capitalize(), entry.sequence], 12, MUTED))
	if is_player: row.add_child(spacer)
	row.add_child(panel)
	if not is_player: row.add_child(spacer)
	row.set_meta("sender_type", entry.sender_type)
	return row

static func ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control: ignore_mouse(child)

static func contact_preview(identity: NPCPresentation, contact: QuestConversation, status: String, action: Callable) -> Button:
	var result := button("", action)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(avatar(identity))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var last: Dictionary = contact.entries.back()
	var name := label(identity.display_name + ("  ●" if contact.unread() else ""), 19)
	name.max_lines_visible = 2
	column.add_child(name)
	var preview := label(last.message_text.left(80), 15, MUTED)
	preview.max_lines_visible = 2
	preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(preview)
	column.add_child(label(status + "  ·  #" + str(last.sequence), 13, Color("8ecfba")))
	row.add_child(column)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 12)
	margin.add_child(row)
	ignore_mouse(margin)
	result.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.custom_minimum_size.y = 138
	margin.resized.connect(func():
		if is_instance_valid(result): result.custom_minimum_size.y = maxf(138, margin.get_combined_minimum_size().y))
	return result
