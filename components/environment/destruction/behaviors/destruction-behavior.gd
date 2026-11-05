class_name DestructionBehavior extends Resource
@export var enabled := true
## Delay BEFORE this behavior; the following behavior waits, preserving authored order.
@export_range(0, 30) var delay_seconds := 0.0
func validate() -> PackedStringArray:
	return PackedStringArray(["Behavior delay must be finite and 0–30 seconds"]) if not is_finite(delay_seconds) or delay_seconds < 0 or delay_seconds > 30 else PackedStringArray()
func execute(_context: DestructionContext) -> void:
	pass
