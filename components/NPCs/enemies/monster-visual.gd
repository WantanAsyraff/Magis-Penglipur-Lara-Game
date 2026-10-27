class_name MonsterVisual extends Node2D
## Provisional Godot-native art; no enemy behavior lives in this component.
@export_enum("Fish", "Dragonfly", "Crab", "Crocodile") var shape: int = 0
@export var colour: Color = Color(0.3, 0.7, 0.55)
var elapsed: float = 0
func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
func _draw() -> void:
	var c := colour
	if get_parent() is Enemy:
		if get_parent().current_state == Enemy.State.HURT: c = Color.WHITE
		elif get_parent().current_state == Enemy.State.ATTACK: c = c.lightened(.35)
	match shape:
		0:
			draw_set_transform(Vector2.ZERO, 0, Vector2(1.6, .65))
			draw_circle(Vector2.ZERO, 18, c)
			draw_set_transform(Vector2.ZERO)
			draw_colored_polygon(PackedVector2Array([Vector2(-22, 0), Vector2(-40, -14), Vector2(-40, 14)]), c)
			draw_circle(Vector2(17, -3), 3, Color.BLACK)
		1:
			var wing := sin(elapsed * 30) * 5
			for side in [-1, 1]:
				draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(-30, side * (14 + wing)), Vector2(25, side * (18 + wing))]), Color(c, .65))
			draw_line(Vector2(-22, 0), Vector2(15, 0), c, 8)
			draw_circle(Vector2(18, 0), 7, c.lightened(.3))
		2:
			for side in [-1, 1]:
				for i in 3: draw_line(Vector2(side * 15, -8 + i * 8), Vector2(side * 38, -16 + i * 15), c, 4)
				draw_circle(Vector2(side * 32, -20), 9, c)
			draw_circle(Vector2.ZERO, 22, c)
			draw_line(Vector2(-9, -12), Vector2(-9, -25), c, 4)
			draw_line(Vector2(9, -12), Vector2(9, -25), c, 4)
		3:
			draw_colored_polygon(PackedVector2Array([Vector2(-65, 5), Vector2(-30, -15), Vector2(48, -15), Vector2(65, 5), Vector2(30, 18), Vector2(-30, 15)]), c)
			for x in [-25, 20]:
				draw_line(Vector2(x, 5), Vector2(x - 6, 27), c, 8)
			draw_circle(Vector2(45, -9), 3, Color.BLACK)
