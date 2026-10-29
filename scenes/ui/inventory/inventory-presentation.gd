class_name InventoryPresentation extends RefCounted
const CATEGORIES := ["Consumable","Equipment","Key item","Quest item","Material","Component","Food","Weapon material","Rare material"]
static func category(item: ItemData) -> String:
	return CATEGORIES[item.item_type] if item.item_type >= 0 and item.item_type < CATEGORIES.size() else "Other"
static func summary(item: ItemData) -> String:
	var effects := PackedStringArray()
	if item.health_restore > 0: effects.append("Health +%d" % item.health_restore)
	if item.mana_restore > 0: effects.append("Mana +%.0f" % item.mana_restore)
	if item.exp_reward > 0: effects.append("Experience +%d" % item.exp_reward)
	if item.spell_to_unlock: effects.append("Learn "+item.spell_to_unlock.spell_name)
	return " · ".join(effects) if not effects.is_empty() else item.description.replace("\n"," ")
static func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color; box.border_color = border
	box.set_border_width_all(1); box.set_corner_radius_all(6); box.content_margin_left = 16; box.content_margin_right = 16; box.content_margin_top = 12; box.content_margin_bottom = 12
	return box
static func icon(item: ItemData, size_: int) -> Control:
	if item.item_icon:
		var texture := TextureRect.new(); texture.texture = item.item_icon; texture.custom_minimum_size = Vector2(size_,size_); texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; texture.mouse_filter = Control.MOUSE_FILTER_IGNORE; return texture
	var label := Label.new(); label.text = item.item_name.left(2).to_upper(); label.custom_minimum_size = Vector2(size_,size_); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.add_theme_font_size_override("font_size",22); return label
static func preview(item: ItemData) -> Control:
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel",style(Color("eaf2ef"),Color("237a72")))
	var row := HBoxContainer.new(); panel.add_child(row); row.add_child(icon(item,36))
	var label := Label.new(); label.text = item.item_name; row.add_child(label); return panel
