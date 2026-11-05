class_name PersistentHazardBehavior extends DestructionBehavior
enum ReentryPolicy { REFRESH_WHILE_INSIDE, ONCE_PER_ACTOR }
@export_group("Area and lifetime")
@export var hazard_scene: PackedScene
@export_range(1, 2000) var radius := 180.0
@export_range(0.1, 60) var duration := 6.0
@export_range(0.05, 10) var tick_interval := 0.5
@export var targets: DestructionTargetPolicy = DestructionTargetPolicy.new()
@export var reentry_policy: ReentryPolicy = ReentryPolicy.REFRESH_WHILE_INSIDE
@export_group("Damage and supported status")
@export_range(0, 10000) var damage_per_tick := 2.0
@export var damage_kind: EnvironmentalDamage.Kind = EnvironmentalDamage.Kind.THERMAL
## Use runtime-supported handlers. Poison preset uses periodic direct damage, not a fake status.
@export var status_effect: ApplyStatusEffect
@export_group("Presentation")
@export var hazard_particles: PackedScene
@export var hazard_sound: AudioStream
@export var color := Color("83cc73")
@export_range(0, 3) var fade_in_duration := 0.25
@export_range(0, 3) var fade_out_duration := 0.5
const SUPPORTED := ["stun", "slow", "silence", "cooled", "resonance", "conductive", "magnetized", "brittle", "wet", "buff_defense", "buff_damage"]
func validate() -> PackedStringArray:
	var errors := super.validate()
	for value in [radius, duration, tick_interval, damage_per_tick, fade_in_duration, fade_out_duration]:
		if not is_finite(value) or value < 0: errors.append("Hazard values must be finite and nonnegative")
	if damage_per_tick > 10000 or fade_in_duration > 3 or fade_out_duration > 3: errors.append("Hazard exceeds damage/fade bounds")
	if radius <= 0 or radius > 2000 or duration < 0.1 or duration > 60 or tick_interval < 0.05 or tick_interval > 10 or targets == null: errors.append("Invalid hazard area, duration, interval or target policy")
	if status_effect:
		errors.append_array(status_effect.validate())
		if status_effect.status not in SUPPORTED or status_effect.stacking == ActiveEffectManager.StackPolicy.STACK: errors.append("Hazard status needs a supported handler and a non-stacking policy")
	return errors
func execute(context: DestructionContext) -> void:
	var scene := hazard_scene if hazard_scene else load("res://components/environment/destruction/effects/persistent-hazard.tscn") as PackedScene
	var effect := scene.instantiate()
	if not effect is DestructionHazard: effect.free(); push_warning("Hazard scene must extend DestructionHazard"); return
	effect.context = context; effect.definition = self
	context.runtime.spawn_node(effect, context, context.position, duration + fade_out_duration + 0.1)
