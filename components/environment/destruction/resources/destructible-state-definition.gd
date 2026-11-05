class_name DestructibleStateDefinition extends Resource
## A health state is selected at or below this threshold. Lowest qualifying threshold wins.
@export var state_id: StringName = &"intact"
@export_range(0, 1) var health_threshold_ratio := 1.0
@export_group("Appearance")
@export var sprite_texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var animation_name: StringName = &"idle"
@export var modulate_color := Color.WHITE
@export var visual_offset := Vector2.ZERO
@export var visual_scale := Vector2.ONE
@export_group("Collision and interactions")
@export var collision_enabled := true
@export var interaction_enabled := true
@export_group("Transition feedback")
@export var transition_sound: AudioStream
@export var transition_particles: PackedScene
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if state_id == &"" or not is_finite(health_threshold_ratio) or health_threshold_ratio < 0 or health_threshold_ratio > 1: errors.append("State needs an ID and a threshold between 0 and 1")
	if not visual_offset.is_finite() or not visual_scale.is_finite() or visual_scale.x <= 0 or visual_scale.y <= 0: errors.append("Invalid state visual transform")
	return errors
