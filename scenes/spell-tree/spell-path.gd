extends Control

# Key: subject_id (String), Value: SubjectNode (Instance)
var nodes_map: Dictionary = {}

func _draw():
	var line_color = Color(0.4, 0.7, 1.0, 0.5) # Glowy blue
	var line_width = 3.0

	for id in nodes_map:
		var child_node = nodes_map[id]
		var data = child_node.subject_data
		
		for pre_id in data.prerequisites:
			if nodes_map.has(pre_id):
				var parent_node = nodes_map[pre_id]
				
				# Draw from right center of parent to left center of child
				var start = parent_node.position + Vector2(parent_node.size.x, parent_node.size.y / 2)
				var end = child_node.position + Vector2(0, child_node.size.y / 2)
				
				# Curvy Bezier line for a professional look
				_draw_bezier_path(start, end, line_color, line_width)

func _draw_bezier_path(start: Vector2, end: Vector2, color: Color, width: float):
	var cp1 = start + Vector2(100, 0)
	var cp2 = end - Vector2(100, 0)
	var points = PackedVector2Array()
	for i in range(21):
		var t = i / 20.0
		var p = start.cubic_interpolate(end, cp1, cp2, t)
		points.append(p)
	draw_polyline(points, color, width, true)
