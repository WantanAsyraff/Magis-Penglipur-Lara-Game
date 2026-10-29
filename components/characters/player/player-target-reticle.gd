extends Node2D
@export var binding_action: StringName = &"cycle_target"
@export var caption: String = "LOCK"
@export var tint: Color = Color(1.0,0.8,0.35)
## A target child shares the enemy's native 2D rendering/interpolation exactly.
func _ready() -> void:
	z_index = 100
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT

func visual_bounds() -> Rect2:
	var bounds := Rect2(Vector2.ZERO,Vector2.ZERO)
	var found := false
	for child in get_parent().get_children():
		if child is CollisionShape2D and child.shape != null and not child.disabled:
			var rect: Rect2 = child.transform * child.shape.get_rect()
			bounds = bounds.merge(rect) if found else rect
			found = true
	return bounds

func _draw() -> void:
	var rect := visual_bounds().grow(12)
	var start := rect.position
	var end := rect.end
	for point in [Vector2(start.x,start.y), Vector2(end.x,start.y), Vector2(start.x,end.y), Vector2(end.x,end.y)]:
		var direction := Vector2(1 if point.x == start.x else -1, 1 if point.y == start.y else -1)
		draw_line(point,point+Vector2(18*direction.x,0),tint,3,true)
		draw_line(point,point+Vector2(0,18*direction.y),tint,3,true)
	var key := "Q"
	var events := InputMap.action_get_events(binding_action)
	if not events.is_empty() and events[0] is InputEventKey:
		key = OS.get_keycode_string(events[0].physical_keycode if events[0].physical_keycode else events[0].keycode)
	draw_string(ThemeDB.fallback_font,start+Vector2(0,-10),"%s · %s Next" % [caption,key],HORIZONTAL_ALIGNMENT_LEFT,-1,16,tint)
