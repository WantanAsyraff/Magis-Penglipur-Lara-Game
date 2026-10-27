class_name NPCSpawnValidator extends Resource
## All dimensions are world units. Marker positions denote desired feet/ground.
@export var allowed_region := Rect2(-800, -400, 1600, 800)
@export var body_size := Vector2(84, 236)
@export var obstacle_margin: float = 12
@export var interaction_clearance: float = 90
@export var minimum_separation: float = 240
@export var max_attempts: int = 24
@export_flags_2d_physics var solid_mask: int = 16
@export var ground_search: float = 500
@export var max_step: float = 36
@export var fallback_enabled: bool = false
@export var fallback_feet := Vector2.ZERO
func ground(space: PhysicsDirectSpaceState2D, at: Vector2, exclude: Array[RID] = []) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(at - Vector2(0, 80), at + Vector2(0, ground_search), solid_mask, exclude)
	return space.intersect_ray(query)
func clear(space: PhysicsDirectSpaceState2D, center: Vector2, size: Vector2, exclude: Array[RID] = []) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = solid_mask
	query.exclude = exclude
	return space.intersect_shape(query, 1).is_empty()
func valid(space: PhysicsDirectSpaceState2D, center: Vector2, region: Rect2, others: Array[Vector2] = [], exclude: Array[RID] = []) -> bool:
	if not region.encloses(Rect2(center - body_size/2, body_size)): return false
	for other in others:
		if other.distance_to(center) < minimum_separation: return false
	if not clear(space, center - Vector2(0, obstacle_margin/2), body_size + Vector2(obstacle_margin*2, obstacle_margin - 8), exclude): return false
	var feet := center + Vector2(0, body_size.y/2)
	for x in [-body_size.x/2, body_size.x/2]:
		var hit := ground(space, feet + Vector2(x, -4), exclude)
		if hit.is_empty() or absf(hit.position.y - feet.y) > max_step: return false
	# At least one full-height player approach lane, on grounded floor.
	for side in [-1, 1]:
		var approach := center + Vector2(side * (body_size.x/2 + interaction_clearance/2), 0)
		if not region.has_point(approach): continue
		if not clear(space, approach, Vector2(interaction_clearance, body_size.y - 6), exclude): continue
		var hit := ground(space, approach + Vector2(0, body_size.y/2 - 4), exclude)
		if not hit.is_empty() and absf(hit.position.y - feet.y) <= max_step: return true
	return false
func reachable(space: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, exclude: Array[RID] = []) -> bool:
	# Conservative walkable 2D-platform corridor. No invented jumping/navmesh route.
	if absf(from.y - to.y) > max_step: return false
	var steps := ceili(absf(to.x - from.x)/32.0)
	if steps > 256: return false
	for i in range(steps + 1):
		var at := from.lerp(to, float(i)/maxi(steps, 1))
		if not clear(space, at, body_size - Vector2(2, 6), exclude): return false
		var hit := ground(space, at + Vector2(0, body_size.y/2 - 4), exclude)
		if hit.is_empty() or absf(hit.position.y - (at.y + body_size.y/2)) > max_step: return false
	return true
func choose(space: PhysicsDirectSpaceState2D, origin: Vector2, markers: Array[Vector2], access: Array[Vector2], others: Array[Vector2]) -> Dictionary:
	var candidates := markers.duplicate()
	for i in max_attempts:
		candidates.append(origin + allowed_region.position + Vector2(randf()*allowed_region.size.x, randf()*allowed_region.size.y))
	if fallback_enabled: candidates.append(origin + fallback_feet)
	for feet in candidates:
		var hit := ground(space, feet)
		if hit.is_empty(): continue
		var center: Vector2 = hit.position - Vector2(0, body_size.y/2 + 2)
		if not valid(space, center, Rect2(origin + allowed_region.position, allowed_region.size), others): continue
		for anchor in access:
			var base := ground(space, anchor)
			if base.is_empty(): continue
			var approach: Vector2 = base.position - Vector2(0, body_size.y/2 + 2)
			if reachable(space, approach, center): return {"position": center}
	return {}
