class_name DestructibleMaterialDefinition extends Resource
@export_group("Identity")
@export var material_id: StringName = &"generic"
@export var display_name := "Generic"
@export_group("Damage response")
@export_range(0, 10) var impact_multiplier := 1.0
@export_range(0, 10) var thermal_multiplier := 1.0
@export_range(0, 10) var electrical_multiplier := 1.0
@export_range(0, 10) var pressure_multiplier := 1.0
@export_range(0, 10) var sonic_multiplier := 1.0
@export_range(0, 100000) var minimum_break_force := 0.0
@export_range(0, 1) var knockback_resistance := 0.0
@export_group("Feedback")
@export var default_damage_sound: AudioStream
@export var default_break_sound: AudioStream
@export var default_impact_particles: PackedScene
@export var default_destroy_particles: PackedScene
func multiplier(kind: EnvironmentalDamage.Kind) -> float:
	return [impact_multiplier, thermal_multiplier, electrical_multiplier, pressure_multiplier, sonic_multiplier][kind]
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for value in [impact_multiplier, thermal_multiplier, electrical_multiplier, pressure_multiplier, sonic_multiplier, minimum_break_force, knockback_resistance]:
		if not is_finite(value) or value < 0: errors.append("Material values must be finite and nonnegative")
	if knockback_resistance > 1: errors.append("Knockback resistance must be 0–1")
	return errors
