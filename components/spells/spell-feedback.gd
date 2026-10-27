class_name SpellFeedback extends Node2D
var colour: Color = Color.WHITE
var remaining: float = 0.3
static func flash(target: Node2D, tint: Color) -> void:
	var feedback := SpellFeedback.new()
	feedback.colour = tint
	target.add_child(feedback)
func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0: queue_free()
	queue_redraw()
func _draw() -> void:
	draw_arc(Vector2.ZERO, 12 + (0.3 - remaining) * 50, 0, TAU, 24, Color(colour, maxf(remaining / 0.3, 0)), 2)
