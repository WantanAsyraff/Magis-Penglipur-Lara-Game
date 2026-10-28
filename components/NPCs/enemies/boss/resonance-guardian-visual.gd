extends Node2D
# Native placeholder poses keep the inherited Boss AI independent of final art.
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var boss := get_parent() as Boss
	if boss.current_phase == null: return
	var tint := boss.current_phase.phase_colour
	var charging := boss.current_state == Boss.State.ATTACK and is_instance_valid(boss.telegraph)
	var transitioning := boss.current_state == Boss.State.PHASE_TRANSITION
	var stone := Color("394758")
	if boss.current_state == Boss.State.HURT: stone = Color("c4b3a2")
	if boss.current_state == Boss.State.DEATH: modulate.a = .35
	var bob := sin(elapsed * 3) * 3
	_draw_shadow(Vector2(0, 96), Vector2(100, 12), Color(0, 0, 0, .3))
	draw_colored_polygon(PackedVector2Array([Vector2(-65,-70),Vector2(65,-70),Vector2(80,45),Vector2(45,70),Vector2(-45,70),Vector2(-80,45)]), stone)
	draw_rect(Rect2(-58, 65, 44, 35), stone)
	draw_rect(Rect2(14, 65, 44, 35), stone)
	var arm_y := -110.0 if charging else -38.0 + bob
	draw_rect(Rect2(-110, arm_y, 40, 85), stone.lightened(.08))
	draw_rect(Rect2(70, arm_y, 40, 85), stone.lightened(.08))
	draw_circle(Vector2(0, -8), 34, tint.darkened(.7))
	draw_arc(Vector2(0, -8), 34, elapsed, elapsed + TAU, 32, tint, 4, true)
	draw_circle(Vector2(0, -8), 17 + sin(elapsed * 5) * 2, tint)
	draw_rect(Rect2(-42, -116 + bob, 84, 48), stone.lightened(.12))
	draw_line(Vector2(-25, -92 + bob), Vector2(25, -92 + bob), tint, 6, true)
	if transitioning:
		draw_arc(Vector2.ZERO, 140 + sin(elapsed * 15) * 8, 0, TAU, 64, tint, 6, true)
		draw_arc(Vector2.ZERO, 155, -elapsed * 4, -elapsed * 4 + PI, 32, tint, 3, true)

func _draw_shadow(center: Vector2, radius: Vector2, colour: Color) -> void:
	var points := PackedVector2Array()
	for i in 40: points.append(center + Vector2(cos(TAU * i / 40), sin(TAU * i / 40)) * radius)
	draw_colored_polygon(points, colour)
