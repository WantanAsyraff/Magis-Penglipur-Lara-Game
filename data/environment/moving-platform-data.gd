class_name MovingPlatformData extends Resource
enum Route { LOOP, PING_PONG, ONE_SHOT }
@export var size: Vector2 = Vector2(180,24)
@export var speed: float = 120.0
@export var wait_seconds: float = 0.5
@export var route: Route = Route.PING_PONG
@export var initially_enabled: bool = false
@export var initially_powered: bool = true
@export var visual: EnvironmentVisualData
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid platform size, speed or dwell time"]) if not size.is_finite() or size.x <= 0 or size.y <= 0 or not is_finite(speed) or speed <= 0 or not is_finite(wait_seconds) or wait_seconds < 0 else PackedStringArray()
