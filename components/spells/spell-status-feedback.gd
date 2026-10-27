class_name SpellStatusFeedback extends Node2D
var hitbox: HitboxComponent
func _process(_delta: float) -> void:
	if not is_instance_valid(hitbox): queue_free(); return
	visible = not hitbox.effects.entries.is_empty()
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(hitbox): return
	var i := 0
	for entry in hitbox.effects.entries.slice(0, 8):
		var c := Color.from_hsv(fmod(absf(float(entry.key.hash())) / 1000, 1), .6, 1)
		var at := Vector2(-24 + i * 7, -40)
		draw_circle(at, 3, c)
		draw_line(at + Vector2(-2, -5), at + Vector2(-2, -5 - minf(entry.remaining, 10)), c, 2)
		i += 1
