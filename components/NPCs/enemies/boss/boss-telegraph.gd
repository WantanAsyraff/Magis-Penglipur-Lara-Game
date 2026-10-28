class_name BossTelegraph extends Node2D

var attack: BossAttackData
var duration := 1.0
var elapsed := 0.0
var heading := Vector2.RIGHT
var dash_length := 0.0

func _ready() -> void:
	z_index = 8
	add_to_group("boss_telegraph")

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if attack == null: return
	var tint := attack.telegraph_colour
	var fill := Color(tint, 0.10 + 0.14 * clampf(elapsed / duration, 0, 1))
	match attack.kind:
		BossAttackData.AttackKind.AOE_SLAM:
			draw_circle(Vector2.ZERO, attack.aoe_radius, fill)
			draw_arc(Vector2.ZERO, attack.aoe_radius, 0, TAU, 72, tint, 4, true)
			draw_arc(Vector2.ZERO, attack.aoe_radius * clampf(elapsed / duration, 0, 1), 0, TAU, 64, Color(tint, .65), 2, true)
		BossAttackData.AttackKind.MELEE_SLAM:
			var points := PackedVector2Array([Vector2.ZERO])
			var arc := deg_to_rad(attack.melee_arc_degrees)
			for i in 41: points.append(Vector2.from_angle(heading.angle() - arc / 2 + arc * i / 40) * attack.melee_range)
			if attack.melee_arc_degrees >= 359.9:
				draw_circle(Vector2.ZERO, attack.melee_range, fill)
				draw_arc(Vector2.ZERO, attack.melee_range, 0, TAU, 64, tint, 3, true)
			else:
				draw_colored_polygon(points, fill)
				draw_polyline(points, tint, 3, true)
		BossAttackData.AttackKind.MELEE_DASH:
			var end := heading * dash_length
			var radius := attack.melee_range * 1.5
			draw_line(Vector2.ZERO, end, fill, radius * 2, true)
			draw_circle(Vector2.ZERO, radius, fill)
			draw_circle(end, radius, fill)
			draw_line(Vector2.ZERO, end, tint, 5, true)
			draw_line(end, end - heading.rotated(.5) * 42, tint, 5, true)
			draw_line(end, end - heading.rotated(-.5) * 42, tint, 5, true)
		_:
			draw_arc(Vector2.ZERO, 95, -PI / 2, -PI / 2 + TAU * clampf(elapsed / duration, .02, 1), 48, tint, 5, true)
			draw_line(heading * 110, heading * 185, tint, 5, true)
	var height := attack.aoe_radius if attack.kind == BossAttackData.AttackKind.AOE_SLAM else 140.0
	draw_string(ThemeDB.fallback_font, Vector2(-90, -height - 24), attack.attack_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 180, 18, tint)
