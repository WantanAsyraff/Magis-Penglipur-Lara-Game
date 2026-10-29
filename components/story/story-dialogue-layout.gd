extends "res://addons/dialogic/Modules/DefaultLayoutParts/Base_Default/default_layout_base.gd"
## Only opted-in story sequences use this layout; ordinary NPC styles remain unchanged.
func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()
func _fit() -> void:
	var screen := get_viewport().get_visible_rect().size
	for part in get_layers():
		if part.get_script().resource_path.ends_with("vn_textbox_layer.gd"):
			part.set("box_size",Vector2(maxf(300,screen.x-72),minf(300,screen.y*.32)))
			part.set("box_margin_bottom",104)
			part.set("text_size",maxi(20,roundi(screen.x/64)))
			part.set("name_label_custom_font_size",maxi(22,roundi(screen.x/56)))
			part.apply_export_overrides()
