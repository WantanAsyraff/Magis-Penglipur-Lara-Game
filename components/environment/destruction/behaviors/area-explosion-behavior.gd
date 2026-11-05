class_name AreaExplosionBehavior extends DestructionBehavior
@export_group("Explosion")
@export_range(1, 2000) var explosion_radius := 180.0
@export_range(0, 100000) var base_damage := 30.0
@export var damage_falloff: Curve
@export_range(0, 5000) var knockback_force := 400.0
@export var damage_kind: EnvironmentalDamage.Kind = EnvironmentalDamage.Kind.PRESSURE
@export var targets: DestructionTargetPolicy = DestructionTargetPolicy.new()
@export_group("Chain reactions")
@export var chain_reaction_enabled := true
@export_range(0, 10) var chain_reaction_multiplier := 1.0
@export_group("Presentation")
@export var explosion_particles: PackedScene
@export var explosion_sound: AudioStream
@export var color := Color("ffb357")
@export var camera_feedback_enabled := true
func validate() -> PackedStringArray:
	var errors := super.validate()
	for value in [explosion_radius, base_damage, knockback_force, chain_reaction_multiplier]:
		if not is_finite(value) or value < 0: errors.append("Explosion values must be finite and nonnegative")
	if base_damage > 100000 or knockback_force > 5000 or chain_reaction_multiplier > 10: errors.append("Explosion exceeds damage/force/chain safety bounds")
	if explosion_radius <= 0 or explosion_radius > 2000 or targets == null: errors.append("Invalid explosion radius or target policy")
	return errors
func execute(context: DestructionContext) -> void:
	var effect := load("res://components/environment/destruction/effects/explosion-area.tscn").instantiate() as DestructionExplosion
	effect.context = context; effect.definition = self
	context.runtime.spawn_node(effect, context, context.position, 2.0)
