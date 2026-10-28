class_name StatusEffectIcon extends Control
var row: Dictionary = {}
var remaining: float = 0
var duration: float = 1
var panel := StyleBoxFlat.new()
func _ready() -> void:
	custom_minimum_size = Vector2(52, 52)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
func present(value: Dictionary) -> void:
	row = value
	remaining = value.remaining
	duration = maxf(value.duration, .001)
	var info := StatusPresentation.describe(row.key)
	tooltip_text = "%s%s — %s\n%.1fs remaining" % [info[0], " ×%d" % row.count if row.count > 1 else "", info[1], remaining]
	queue_redraw()
func _draw() -> void:
	if row.is_empty(): return
	var good: bool = row.beneficial
	var accent := Color("86bcb2") if good else Color("d39792")
	draw_style_box(_panel(accent), Rect2(Vector2.ZERO, size))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE * (minf(size.x,size.y)/34.0))
	# Buffs have a rounded upper mark; debuffs a triangular warning mark.
	if good: draw_arc(Vector2(17, 8), 3, PI, TAU, 8, accent, 1.5, true)
	else: draw_polyline(PackedVector2Array([Vector2(13,9),Vector2(17,4),Vector2(21,9)]), accent, 1.5, true)
	var glyph: String = StatusPresentation.describe(row.key)[2]
	match glyph:
		"heal":
			draw_line(Vector2(17,13),Vector2(17,25),accent,2)
			draw_line(Vector2(11,19),Vector2(23,19),accent,2)
		"shield": draw_polyline(PackedVector2Array([Vector2(10,13),Vector2(24,13),Vector2(23,22),Vector2(17,27),Vector2(11,22),Vector2(10,13)]),accent,1.5,true)
		"speed", "slow":
			for x in [11,18]: draw_polyline(PackedVector2Array([Vector2(x,14),Vector2(x+5,19),Vector2(x,24)]),accent,1.5,true)
			if glyph == "slow": draw_line(Vector2(10,27),Vector2(24,12),accent,1.5)
		"mana": draw_polyline(PackedVector2Array([Vector2(17,12),Vector2(24,21),Vector2(17,27),Vector2(10,21),Vector2(17,12)]),accent,1.5,true)
		"silence":
			draw_circle(Vector2(17,19),7,accent,false,1.5,true)
			draw_line(Vector2(10,26),Vector2(24,12),accent,2)
		"stun": draw_polyline(PackedVector2Array([Vector2(20,12),Vector2(13,20),Vector2(20,20),Vector2(14,27)]),accent,2,true)
		"damage":
			draw_line(Vector2(11,13),Vector2(23,25),accent,2)
			draw_line(Vector2(23,13),Vector2(11,25),accent,2)
		_: draw_circle(Vector2(17,19),5,accent,false,1.5,true)
	draw_line(Vector2(3,32), Vector2(3+28*clampf(remaining/duration,0,1),32),accent,1)
	if row.count > 1: draw_string(ThemeDB.fallback_font, Vector2(22,29), str(row.count), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
func _panel(accent: Color) -> StyleBoxFlat:
	panel.bg_color = Color(.04,.055,.08,.8)
	panel.border_color = accent.darkened(.35)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(4)
	return panel
