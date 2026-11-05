class_name SpawnActorBehavior extends DestructionBehavior
enum Pattern { ORIGIN, RANDOM_RADIUS, RADIAL, MARKERS, DIRECTIONAL }
@export_group("Actor")
@export var actor_scene: PackedScene
@export var enemy_data: EnemyData
@export_range(1, 16) var spawn_count := 3
@export_range(0, 1000) var spawn_radius := 120.0
@export var spawn_pattern: Pattern = Pattern.RADIAL
@export var spawn_markers: Array[NodePath] = []
@export var directional_offsets: Array[Vector2] = []
@export_group("Ownership and limits")
@export var inherit_faction := false
@export var configured_faction: StringName = &"enemy"
@export_range(1, 32) var max_active_spawned_actors := 12
@export_range(1, 300) var lifetime := 120.0
@export_range(1, 16) var placement_attempts := 6
func validate() -> PackedStringArray:
	var errors := super.validate()
	if actor_scene == null: errors.append("Actor scene is required")
	if spawn_count < 1 or spawn_count > 16 or max_active_spawned_actors < 1 or max_active_spawned_actors > 32: errors.append("Invalid actor spawn/active count")
	if not is_finite(spawn_radius) or spawn_radius < 0 or spawn_radius > 1000 or not is_finite(lifetime) or lifetime <= 0 or lifetime > 300: errors.append("Invalid actor radius or lifetime")
	if placement_attempts < 1 or placement_attempts > 16: errors.append("Invalid placement attempt limit")
	if spawn_pattern == Pattern.MARKERS and spawn_markers.is_empty(): errors.append("Marker pattern needs marker paths relative to source")
	if spawn_pattern == Pattern.DIRECTIONAL and directional_offsets.is_empty(): errors.append("Directional pattern needs offsets")
	for offset in directional_offsets:
		if not offset.is_finite(): errors.append("Non-finite actor offset")
	if enemy_data: errors.append_array(enemy_data.validate())
	return errors
func execute(context: DestructionContext) -> void:
	var active := 0
	for ref in context.runtime.spawned:
		var node: Node = ref.get_ref()
		if is_instance_valid(node) and node.is_in_group("destruction_actor") and not node.get_meta("combat_dead", false): active += 1
	var exclude: Array[RID] = []
	var source := context.source_object()
	if source is CollisionObject2D: exclude.append(source.get_rid())
	for index in mini(spawn_count, maxi(0, max_active_spawned_actors - active)):
		var desired := context.position
		match spawn_pattern:
			Pattern.RANDOM_RADIUS: desired += Vector2.from_angle(context.rng.randf() * TAU) * sqrt(context.rng.randf()) * spawn_radius
			Pattern.RADIAL: desired += Vector2.from_angle(index * TAU / spawn_count) * spawn_radius
			Pattern.MARKERS:
				var marker := source.get_node_or_null(spawn_markers[index % spawn_markers.size()]) if is_instance_valid(source) else null
				if not marker is Node2D: push_warning("Missing destruction spawn marker"); continue
				desired = marker.global_position
			Pattern.DIRECTIONAL: desired += directional_offsets[index % directional_offsets.size()]
		var safe := false
		for attempt in placement_attempts:
			if context.runtime.safe_spawn_position(actor_scene, desired, exclude): safe = true; break
			desired += Vector2(0, -24)
		if not safe: continue
		var node := actor_scene.instantiate()
		if not node is Node2D: node.free(); push_warning("Actor scene root must be Node2D"); return
		if enemy_data:
			if not node is Enemy: node.free(); push_warning("EnemyData requires an Enemy root"); return
			node.enemy_data = enemy_data
		node.set_meta("faction_id", context.faction if inherit_faction else configured_faction)
		node.set_meta("spell_team", context.faction if inherit_faction else configured_faction)
		if node is Enemy:
			# Enemy._ready applies its Resource faction. Override a PRIVATE definition before ready.
			var definition: EnemyData = enemy_data if enemy_data else node.enemy_data
			if definition:
				node.enemy_data = definition.duplicate()
				node.enemy_data.faction_id = context.faction if inherit_faction else configured_faction
		node.add_to_group("destruction_actor")
		context.runtime.spawn_node(node, context, desired, lifetime)
