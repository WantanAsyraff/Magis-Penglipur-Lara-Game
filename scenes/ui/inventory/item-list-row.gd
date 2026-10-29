class_name ItemListRow extends Button
signal selected_id(id: String)
signal favorite_id(id: String)
var item: ItemData
var star: Button
var title: Label
var subtitle: Label
var quantity: Label
var marked := false
func setup(data: ItemData) -> void:
	item = data; custom_minimum_size.y = 80; size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new(); row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); row.offset_left = 12; row.offset_right = -12; row.add_theme_constant_override("separation",14); row.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(row)
	star = Button.new(); star.flat = true; star.custom_minimum_size.x = 32; star.tooltip_text = "Favorite · Y / gamepad Y"; row.add_child(star)
	star.pressed.connect(func(): favorite_id.emit(item.item_id))
	row.add_child(InventoryPresentation.icon(item,42))
	var text := VBoxContainer.new(); text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; text.size_flags_vertical = Control.SIZE_SHRINK_CENTER; text.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(text)
	title = Label.new(); title.add_theme_font_size_override("font_size",19); title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; title.mouse_filter = Control.MOUSE_FILTER_IGNORE; text.add_child(title)
	subtitle = Label.new(); subtitle.add_theme_font_size_override("font_size",13); subtitle.add_theme_color_override("font_color",Color("657477")); subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE; text.add_child(subtitle)
	quantity = Label.new(); quantity.custom_minimum_size.x = 54; quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(quantity)
	pressed.connect(func(): selected_id.emit(item.item_id))
	focus_entered.connect(func(): selected_id.emit(item.item_id))
	refresh()
func refresh() -> void:
	if item == null or star == null: return
	title.text = item.item_name; subtitle.text = InventoryPresentation.category(item)+" · "+InventoryPresentation.summary(item)
	quantity.text = "×%d" % Inventory_Manager.get_item_quantity(item.item_id)
	star.text = "★" if Inventory_Manager.favorites.has(item.item_id) else "☆"
	tooltip_text = item.item_name+"\n"+item.description
func mark(value: bool) -> void:
	marked = value
	if has_theme_stylebox("selected" if value else "normal","InventoryRow"):
		add_theme_stylebox_override("normal",get_theme_stylebox("selected" if value else "normal","InventoryRow")); return
	add_theme_stylebox_override("normal",InventoryPresentation.style(Color("e7f1ed") if value else Color("ffffff"),Color("277c72") if value else Color("e2e6e2")))
func _get_drag_data(_at: Vector2) -> Variant:
	if item == null or not Inventory_Manager.has_item(item.item_id): return null
	set_drag_preview(InventoryPresentation.preview(item))
	return {"type":"inventory_item","id":item.item_id,"from_slot":-1}
