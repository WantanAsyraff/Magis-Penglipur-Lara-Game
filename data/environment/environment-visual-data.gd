class_name EnvironmentVisualData extends Resource
## Optional presentation only. Gameplay collision and timing remain on the prop.
@export var texture: Texture2D
@export var frames: SpriteFrames
@export var visual_scene: PackedScene
@export var offset: Vector2 = Vector2.ZERO
@export var scale: Vector2 = Vector2.ONE
@export var tint: Color = Color(0.32,0.72,0.69)
@export var activate_sound: AudioStream
@export var deactivate_sound: AudioStream
@export var particles: PackedScene
@export var idle_animation: StringName = &"idle"
@export var active_animation: StringName = &"active"
@export var broken_animation: StringName = &"broken"
func validate() -> PackedStringArray:
	return PackedStringArray(["Visual transform must be finite and scale nonzero"]) if not offset.is_finite() or not scale.is_finite() or scale.x == 0 or scale.y == 0 else PackedStringArray()
