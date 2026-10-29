class_name InventoryUI extends Control
signal closed
@export var background_color: Color = Color("f6f6f0")
@export var background_texture: Texture2D
@export_range(16,64) var page_margin: int = 32
@export var open_sound: AudioStream
@export var success_sound: AudioStream
@export var failure_sound: AudioStream
var audio: AudioStreamPlayer
const FILTERS := ["All items","Equipment","Consumables","Food","Materials","Components","Quest items","Key items","Favorites"]
const SORTS := ["Name A–Z","Name Z–A","Category","Quantity","Ringgit value","Favorites first"]
const SLOT_NAMES := ["Weapon","Offhand","Robe","Accessory 1","Accessory 2"]
var _refresh_pending := false
var _focus_serial := 0
var _last_focused_row: Control
var rows: Dictionary = {}
var selected_id := ""
var visible_ids: Array[String] = []
var list: VBoxContainer
var scroll: ScrollContainer
var category: OptionButton
var sort: OptionButton
var search: LineEdit
var capacity: Label
var empty: Label
var details: VBoxContainer
var feedback: Label
var tabs: TabBar
var inventory_content: Control
var equipment_content: Control
var equipment_slots: Array[EquipmentDropTarget] = []
var return_target: EquipmentDropTarget
var selected_slot := -1
var _detail_stamp := "uninitialized"
var displayed: ItemData
var use_button: Button
var equip_button: Button
var drop_button: Button
var slot_dialog: ConfirmationDialog
var drop_dialog: ConfirmationDialog
var drop_prompt: Label
var drop_quantity: SpinBox
var _drop_id := ""
var search_keyboard: AcceptDialog
var _focused_before_dialog: Control
func label(text_: String, size_: int = 16) -> Label:
	var node := Label.new(); node.text = text_; node.add_theme_font_size_override("font_size",size_); return node
func button(text_: String, callback: Callable) -> Button:
	var node := Button.new(); node.text = text_; node.pressed.connect(callback); return node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new(); bg.color = background_color; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	if background_texture:
		var art := TextureRect.new(); art.texture = background_texture; art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(art)
	audio = AudioStreamPlayer.new(); add_child(audio); audio.stream = open_sound
	if audio.stream: audio.play()
	modulate.a = 0; create_tween().tween_property(self,"modulate:a",1.0,.12)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,page_margin)
	add_child(margin)
	var page := VBoxContainer.new(); page.add_theme_constant_override("separation",16); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var heading := VBoxContainer.new(); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(heading)
	heading.add_child(label("MAGIS  /  PERSONAL RECORD",13)); heading.add_child(label("Inventory",36))
	capacity = label(""); capacity.size_flags_vertical = Control.SIZE_SHRINK_CENTER; header.add_child(capacity)
	var close_button := button("Close  ×",func(): closed.emit()); close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER; header.add_child(close_button)
	tabs = TabBar.new(); tabs.add_tab("Inventory"); tabs.add_tab("Equipment"); page.add_child(tabs); tabs.tab_changed.connect(_tab_changed)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",28); page.add_child(body)
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left.size_flags_stretch_ratio = 1.6; body.add_child(left)
	inventory_content = VBoxContainer.new(); inventory_content.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(inventory_content)
	var filters := HBoxContainer.new(); inventory_content.add_child(filters)
	category = OptionButton.new(); category.name = "Category"; category.custom_minimum_size.x = 170
	for text_ in FILTERS: category.add_item(text_)
	filters.add_child(category); category.item_selected.connect(func(_index): refresh())
	search = LineEdit.new(); search.name = "Search"; search.placeholder_text = "Search items…"; search.size_flags_horizontal = Control.SIZE_EXPAND_FILL; search.clear_button_enabled = true; filters.add_child(search); search.text_changed.connect(func(_text): refresh())
	sort = OptionButton.new(); sort.name = "Sort"
	for text_ in SORTS: sort.add_item(text_)
	filters.add_child(sort); sort.item_selected.connect(func(_index): refresh())
	scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true; inventory_content.add_child(scroll)
	list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",6); scroll.add_child(list)
	empty = label("Your inventory is empty.",20); list.add_child(empty)
	equipment_content = VBoxContainer.new(); equipment_content.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(equipment_content); equipment_content.hide()
	equipment_content.add_child(label("EQUIPMENT RECORD",13))
	for index in 5:
		var slot := EquipmentDropTarget.new(); slot.slot = index; slot.custom_minimum_size.y = 78; slot.alignment = HORIZONTAL_ALIGNMENT_LEFT; equipment_content.add_child(slot); equipment_slots.append(slot)
		slot.pressed.connect(_select_slot.bind(index)); slot.focus_entered.connect(_select_slot.bind(index)); slot.action_result.connect(_result)
	return_target = EquipmentDropTarget.new(); return_target.text = "Return to inventory  ↓"; return_target.tooltip_text = "Drag equipped items here, or select a slot and choose Unequip."; equipment_content.add_child(return_target); return_target.action_result.connect(_result); return_target.pressed.connect(func(): if selected_slot >= 0: _result(Inventory_Manager.unequip_item(selected_slot)))
	var detail_panel := PanelContainer.new(); detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_panel.size_flags_stretch_ratio = 1; detail_panel.add_theme_stylebox_override("panel",InventoryPresentation.style(Color.WHITE,Color("e1e5df"))); body.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; detail_scroll.follow_focus = true; detail_panel.add_child(detail_scroll)
	details = VBoxContainer.new(); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",16); detail_scroll.add_child(details)
	feedback = label(""); feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; page.add_child(feedback)
	page.add_child(label("A / Enter  Select      B / Esc  Close      Y  Favorite      LB / RB  Tabs      X / /  Search",13))
	_build_dialogs(); _build_search_keyboard()
	Inventory_Manager.inventory_changed.connect(func(_item,_qty): schedule_refresh())
	Inventory_Manager.equipment_changed.connect(func(_slot,_item): schedule_refresh())
	Inventory_Manager.preferences_changed.connect(schedule_refresh)
	refresh(); call_deferred("initial_focus")
func initial_focus() -> void:
	if not is_inside_tree(): return
	if not visible_ids.is_empty(): rows[visible_ids[0]].grab_focus()
	else: category.grab_focus()
func matches_filter(item: ItemData) -> bool:
	match category.selected:
		1: return item.item_type == ItemData.ItemType.EQUIPMENT
		2: return item.item_type == ItemData.ItemType.CONSUMABLE
		3: return item.item_type == ItemData.ItemType.FOOD
		4: return item.item_type in [ItemData.ItemType.MATERIAL,ItemData.ItemType.WEAPON_MATERIAL,ItemData.ItemType.RARE_MATERIAL]
		5: return item.item_type == ItemData.ItemType.COMPONENT
		6: return item.item_type == ItemData.ItemType.QUEST_ITEM
		7: return item.item_type == ItemData.ItemType.KEY_ITEM
		8: return Inventory_Manager.favorites.has(item.item_id)
	return true
func less(a: String, b: String) -> bool:
	var first: ItemData = Inventory_Manager.inventory[a].data; var second: ItemData = Inventory_Manager.inventory[b].data
	var av: Variant = first.item_name.to_lower(); var bv: Variant = second.item_name.to_lower()
	match sort.selected:
		2: av = first.item_type; bv = second.item_type
		3: av = -Inventory_Manager.get_item_quantity(a); bv = -Inventory_Manager.get_item_quantity(b)
		4: av = -first.ringgit_value; bv = -second.ringgit_value
		5: av = not Inventory_Manager.favorites.has(a); bv = not Inventory_Manager.favorites.has(b)
	if av == bv: return a < b
	return av > bv if sort.selected == 1 else av < bv
func refresh() -> void:
	if list == null or not is_inside_tree() or is_queued_for_deletion(): return
	_refresh_pending = false
	var old_serial := _focus_serial
	var old_scroll := scroll.scroll_vertical
	var old_index := maxi(0,visible_ids.find(selected_id))
	var lost_focus := false
	for id in rows.keys():
		if not Inventory_Manager.has_item(id):
			if rows[id].has_focus() or (get_viewport().gui_get_focus_owner() != null and rows[id].is_ancestor_of(get_viewport().gui_get_focus_owner())): lost_focus = true
			rows[id].queue_free(); list.remove_child(rows[id]); rows.erase(id)
	visible_ids.clear()
	for item in Inventory_Manager.get_all_items():
		if not rows.has(item.item_id):
			var row: ItemListRow = load("res://scenes/ui/inventory/item-list-row.tscn").instantiate(); list.add_child(row); rows[item.item_id] = row; row.setup(item)
			row.focus_entered.connect(_row_focus.bind(row))
			row.selected_id.connect(select_item); row.favorite_id.connect(func(id): Inventory_Manager.toggle_favorite(id))
		rows[item.item_id].refresh()
		var term := search.text.to_lower().strip_edges()
		var visible_ := matches_filter(item) and (term.is_empty() or term in (item.item_name+" "+item.description+" "+item.item_id).to_lower())
		rows[item.item_id].visible = visible_
		if visible_: visible_ids.append(item.item_id)
	visible_ids.sort_custom(less)
	for index in visible_ids.size(): list.move_child(rows[visible_ids[index]],index)
	empty.visible = visible_ids.is_empty(); empty.text = "Your inventory is empty." if Inventory_Manager.inventory.is_empty() else "No items match your search."
	capacity.text = "%d / %d Item Types" % [Inventory_Manager.reserved_ids().size(),Inventory_Manager.max_slots]
	if not Inventory_Manager.drop_escrow.is_empty(): capacity.text += "  ·  %d units reserved" % Inventory_Manager.drop_escrow.values().reduce(func(total,row): return total+int(row.quantity),0)
	for slot in 5:
		var item := Inventory_Manager.get_equipped(slot)
		equipment_slots[slot].icon = item.item_icon if item else null
		equipment_slots[slot].expand_icon = true; equipment_slots[slot].add_theme_constant_override("icon_max_width",32)
		equipment_slots[slot].text = SLOT_NAMES[slot]+"    /    "+(("["+item.item_name.left(2).to_upper()+"]  " if item.item_icon == null else "")+item.item_name if item else "Empty")
	if tabs.current_tab == 0:
		if selected_id not in visible_ids: selected_id = visible_ids[mini(old_index,visible_ids.size()-1)] if not visible_ids.is_empty() else ""
		select_item(selected_id)
		if lost_focus:
			if rows.has(selected_id): rows[selected_id].grab_focus()
			else: category.grab_focus()
	else: _select_slot(maxi(0,selected_slot))
	_restore_scroll.call_deferred(old_scroll,old_serial)
func select_item(id: String) -> void:
	selected_id = id; selected_slot = -1
	for key in rows: rows[key].mark(key == id)
	_render_details(Inventory_Manager.inventory.get(id,{}).get("data"))
func _select_slot(slot: int) -> void:
	selected_slot = slot
	_render_details(Inventory_Manager.get_equipped(slot))
func _render_details(item: ItemData) -> void:
	var stamp := str([item,selected_slot,Inventory_Manager.get_item_quantity(item.item_id) if item else 0,Inventory_Manager.favorites.has(item.item_id) if item else false,Player_Global_Data.p_curr_health,Player_Global_Data.p_curr_mana])
	if stamp == _detail_stamp: return
	_detail_stamp = stamp
	var focus := get_viewport().gui_get_focus_owner()
	var action_focus: String = focus.text if focus is Button and details.is_ancestor_of(focus) else ""
	displayed = item
	for child in details.get_children(): details.remove_child(child); child.queue_free()
	if item == null:
		if not action_focus.is_empty(): call_deferred("initial_focus")
		details.add_child(label("Select an item",26)); var note := label("Choose an item to inspect its record.\nEmpty equipment slots can be filled from the Inventory tab."); note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(note); return
	details.add_child(InventoryPresentation.icon(item,84))
	var title := label(item.item_name,28); title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(title)
	details.add_child(label(InventoryPresentation.category(item).to_upper(),13))
	var description := label(item.description); description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(description)
	details.add_child(HSeparator.new())
	details.add_child(label("Quantity    %d" % (1 if selected_slot >= 0 else Inventory_Manager.get_item_quantity(item.item_id))))
	if item.ringgit_value > 0: details.add_child(label("Authored value    RM %.2f" % item.ringgit_value))
	var effect_text := InventoryPresentation.summary(item)
	if item.health_restore > 0 or item.mana_restore > 0 or item.exp_reward > 0 or item.spell_to_unlock: details.add_child(label(effect_text))
	if item.item_type in [ItemData.ItemType.KEY_ITEM,ItemData.ItemType.QUEST_ITEM]: details.add_child(label("Protected progression item"))
	if item.equipment_slots != 0:
		var slots := PackedStringArray()
		for i in 5:
			if item.supports_slot(i): slots.append(SLOT_NAMES[i])
		var compatibility := label("Fits    "+", ".join(slots)); compatibility.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(compatibility)
	var actions := HBoxContainer.new(); details.add_child(actions)
	use_button = button("Use",_use); actions.add_child(use_button); var reason := Inventory_Manager.use_reason(item)
	use_button.disabled = selected_slot >= 0 or not reason.is_empty(); use_button.tooltip_text = reason
	equip_button = button("Unequip" if selected_slot >= 0 else "Equip",_equip); actions.add_child(equip_button)
	equip_button.disabled = selected_slot < 0 and (item.item_type != ItemData.ItemType.EQUIPMENT or item.equipment_slots == 0); equip_button.tooltip_text = "Requires authored compatible equipment slots." if equip_button.disabled else "Choose a slot or drag to the Equipment tab."
	drop_button = button("Drop…",_drop); actions.add_child(drop_button); reason = Inventory_Manager.drop_reason(item)
	drop_button.disabled = selected_slot >= 0 or not reason.is_empty(); drop_button.tooltip_text = "Unequip this item first." if selected_slot >= 0 else reason
	var explanations := label("\n".join(PackedStringArray([use_button.tooltip_text if use_button.disabled else "",equip_button.tooltip_text if equip_button.disabled else "",drop_button.tooltip_text if drop_button.disabled else ""])).strip_edges(),13); explanations.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_child(explanations)
	if not action_focus.is_empty():
		var recovered := false
		for action in actions.get_children():
			if action.text == action_focus and not action.disabled: action.call_deferred("grab_focus"); recovered = true
		if not recovered: call_deferred("initial_focus")
	details.add_child(button("★ Unfavorite" if Inventory_Manager.favorites.has(item.item_id) else "☆ Favorite",func(): Inventory_Manager.toggle_favorite(item.item_id)))
func _use() -> void:
	if displayed: _result(Inventory_Manager.use_item(displayed.item_id))
func _equip() -> void:
	if selected_slot >= 0:
		var slot := selected_slot; _result(Inventory_Manager.unequip_item(slot)); equipment_slots[slot].grab_focus(); return
	if displayed == null: return
	_focused_before_dialog = get_viewport().gui_get_focus_owner()
	for child in slot_dialog.get_children():
		if child is VBoxContainer: child.queue_free(); slot_dialog.remove_child(child)
	var choices := VBoxContainer.new(); slot_dialog.add_child(choices)
	var id := displayed.item_id
	for slot in 5:
		if displayed.supports_slot(slot): choices.add_child(button(SLOT_NAMES[slot],func(): _result(Inventory_Manager.equip_item(QuestManager.registry.items.get(id),slot)); slot_dialog.hide(); _restore_focus()))
	slot_dialog.popup_centered(Vector2i(370,250))
	if choices.get_child_count() > 0: choices.get_child(0).grab_focus()
func _drop() -> void:
	if displayed == null: return
	_drop_id = displayed.item_id; _focused_before_dialog = get_viewport().gui_get_focus_owner()
	drop_quantity.max_value = Inventory_Manager.get_item_quantity(_drop_id); drop_quantity.value = 1
	drop_prompt.text = "Drop %s?\nItems remain reserved and return on load or leaving the area." % displayed.item_name
	drop_dialog.popup_centered(Vector2i(520,270)); drop_quantity.grab_focus()
func _build_dialogs() -> void:
	slot_dialog = ConfirmationDialog.new(); slot_dialog.title = "Choose compatible equipment slot"; slot_dialog.get_ok_button().hide(); add_child(slot_dialog); slot_dialog.canceled.connect(_restore_focus); slot_dialog.window_input.connect(_dialog_input.bind(slot_dialog))
	drop_dialog = ConfirmationDialog.new(); drop_dialog.title = "Drop items"; add_child(drop_dialog)
	var drop_content := VBoxContainer.new(); drop_content.add_theme_constant_override("separation",16); drop_dialog.add_child(drop_content)
	drop_prompt = label(""); drop_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; drop_prompt.custom_minimum_size.x = 440; drop_content.add_child(drop_prompt)
	drop_content.add_child(label("Quantity",13))
	drop_quantity = SpinBox.new(); drop_quantity.min_value = 1; drop_quantity.step = 1; drop_content.add_child(drop_quantity)
	drop_dialog.confirmed.connect(func(): _result(Inventory_Manager.drop_item(_drop_id,int(drop_quantity.value))); _restore_focus())
	drop_dialog.canceled.connect(_restore_focus); drop_dialog.window_input.connect(_dialog_input.bind(drop_dialog))
func _restore_focus() -> void:
	if is_instance_valid(_focused_before_dialog) and _focused_before_dialog.is_inside_tree() and _focused_before_dialog.is_visible_in_tree(): _focused_before_dialog.grab_focus()
	else: initial_focus()
func _result(result: ItemActionResult) -> void:
	audio.stream = success_sound if result.ok else failure_sound
	if audio.stream: audio.play()
	feedback.text = result.message; feedback.add_theme_color_override("font_color",Color("247669") if result.ok else Color("a14032"))
	if not result.ok: refresh()
func _tab_changed(index: int) -> void:
	inventory_content.visible = index == 0; equipment_content.visible = index == 1
	if index == 0: select_item(selected_id); initial_focus()
	else: _select_slot(0); equipment_slots[0].grab_focus()
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN and tabs != null:
		var data: Variant = get_viewport().gui_get_drag_data()
		if data is Dictionary and data.get("type") == "inventory_item" and data.get("from_slot") == -1: tabs.current_tab = 1
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event.is_action_pressed("ui_cancel"):
		if search_keyboard.visible: search_keyboard.hide(); initial_focus()
		elif drop_dialog.visible: drop_dialog.hide(); _restore_focus()
		elif slot_dialog.visible: slot_dialog.hide(); _restore_focus()
		elif search.has_focus(): search.release_focus(); initial_focus()
		else: closed.emit()
		get_viewport().set_input_as_handled(); return
	if drop_dialog.visible or slot_dialog.visible or search_keyboard.visible: return
	if search.has_focus() and event is InputEventKey: return
	if event.is_action_pressed("inventory_favorite") and displayed: Inventory_Manager.toggle_favorite(displayed.item_id); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_next_tab"): tabs.current_tab = (tabs.current_tab+1)%2; get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_previous_tab"): tabs.current_tab = (tabs.current_tab+1)%2; get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_search"):
		tabs.current_tab = 0; search.grab_focus()
		if event is InputEventJoypadButton: search_keyboard.popup_centered(Vector2i(460,420)); search_keyboard.get_node("Keys").get_child(0).grab_focus()
		get_viewport().set_input_as_handled()

func _build_search_keyboard() -> void:
	search_keyboard = AcceptDialog.new(); search_keyboard.title = "Search items · gamepad keyboard"; add_child(search_keyboard)
	var keys := GridContainer.new(); keys.name = "Keys"; keys.columns = 6; search_keyboard.add_child(keys)
	for value in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789":
		keys.add_child(button(value,func(): search.text += value; search.text_changed.emit(search.text)))
	keys.add_child(button("Space",func(): search.text += " "; search.text_changed.emit(search.text)))
	keys.add_child(button("⌫",func(): search.text = search.text.left(maxi(0,search.text.length()-1)); search.text_changed.emit(search.text)))
	keys.add_child(button("Clear",func(): search.clear(); refresh()))
	search_keyboard.confirmed.connect(initial_focus); search_keyboard.canceled.connect(initial_focus); search_keyboard.window_input.connect(_dialog_input.bind(search_keyboard))

func _dialog_input(event: InputEvent, dialog: AcceptDialog) -> void:
	if event.is_action_pressed("ui_cancel"):
		dialog.hide(); dialog.canceled.emit(); dialog.set_input_as_handled()

func schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true; refresh.call_deferred()
func _row_focus(row: Control) -> void:
	_focus_serial += 1; _last_focused_row = row
func _restore_scroll(value: int, serial: int) -> void:
	if not is_inside_tree(): return
	scroll.scroll_vertical = value
	if serial != _focus_serial:
		await get_tree().process_frame
		if is_inside_tree() and is_instance_valid(_last_focused_row) and _last_focused_row.is_visible_in_tree(): scroll.ensure_control_visible(_last_focused_row)
