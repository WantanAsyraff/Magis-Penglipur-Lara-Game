class_name ShrapnelBehavior extends DestructionBehavior
enum DirectionMode { RADIAL, CONE, UPWARD_BURST, RANDOMIZED }
@export_group("Projectiles")
@export var projectile_scene: PackedScene
@export_range(1, 48) var projectile_count := 12
@export_range(1, 3000) var projectile_speed := 450.0
@export_range(0.05, 10) var projectile_lifetime := 1.5
@export_range(0, 100000) var projectile_damage := 8.0
@export var targets: DestructionTargetPolicy = DestructionTargetPolicy.new()
@export_group("Distribution")
@export var direction_mode: DirectionMode = DirectionMode.RADIAL
@export var direction := Vector2.RIGHT
@export_range(0, 360) var spread_degrees := 80.0
@export var seed_override := 0
@export_group("Physics")
@export var piercing_enabled := false
@export_range(1, 8) var max_pierces := 1
@export var gravity_enabled := true
@export_range(0, 3) var gravity_scale := 0.3
@export_group("Appearance")
@export var shrapnel_texture: Texture2D
@export var impact_particles: PackedScene
func validate() -> PackedStringArray:
	var errors := super.validate()
	if projectile_count < 1 or projectile_count > 48 or max_pierces < 1 or max_pierces > 8: errors.append("Shrapnel count/pierces exceed safe limits")
	if not direction.is_finite() or direction == Vector2.ZERO or targets == null: errors.append("Shrapnel needs a direction and target policy")
	for value in [projectile_speed, projectile_lifetime, projectile_damage, gravity_scale, spread_degrees]:
		if not is_finite(value) or value < 0: errors.append("Invalid shrapnel value")
	if projectile_damage > 100000 or spread_degrees > 360 or gravity_scale > 3: errors.append("Shrapnel exceeds damage/spread/gravity bounds")
	if projectile_lifetime < 0.05 or projectile_lifetime > 10 or projectile_speed <= 0 or projectile_speed > 3000: errors.append("Invalid shrapnel lifetime or speed")
	return errors
func directions(seed_value: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var rng := RandomNumberGenerator.new(); rng.seed = seed_override if seed_override != 0 else seed_value
	for index in clampi(projectile_count, 1, 48):
		var fraction := 0.5 if projectile_count == 1 else float(index) / (projectile_count - 1)
		var angle := direction.angle()
		match direction_mode:
			DirectionMode.RADIAL: angle = index * TAU / projectile_count
			DirectionMode.CONE: angle += deg_to_rad(lerpf(-spread_degrees / 2, spread_degrees / 2, fraction))
			DirectionMode.UPWARD_BURST: angle = -PI / 2 + deg_to_rad(lerpf(-spread_degrees / 2, spread_degrees / 2, fraction))
			DirectionMode.RANDOMIZED: angle = rng.randf_range(-PI, PI)
		result.append(Vector2.from_angle(angle))
	return result
func execute(context: DestructionContext) -> void:
	var scene := projectile_scene if projectile_scene else load("res://components/environment/destruction/effects/shrapnel-projectile.tscn") as PackedScene
	for heading in directions(hash(context.event_id)):
		var node := scene.instantiate()
		if not node is DestructionShrapnel: node.free(); push_warning("Shrapnel scene must extend DestructionShrapnel"); return
		node.context = context; node.definition = self; node.velocity = heading * projectile_speed
		context.runtime.spawn_node(node, context, context.position, projectile_lifetime)
