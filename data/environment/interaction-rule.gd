class_name InteractionRule extends Resource
## A qualifying cast counts once, even when it has several effects.
enum Event { INTERACT, ENTER, EXIT, CONTACT, PRESSURE, SPELL, DAMAGE, STATUS, IMPULSE, PROJECTILE, SIGNAL }
@export var event: Event = Event.INTERACT
@export_enum("Any", "Damage", "Status", "Impulse", "Healing") var effect_kind: String = "Any"
@export var required_status: StringName = &""
@export var required_capability: StringName = &""
@export_range(1,100) var required_hits: int = 1
@export var required_charge: float = 0.0
@export var minimum_magnitude: float = 0.0
@export var reset_after_activation: bool = false
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if required_hits < 1 or required_hits > 100: errors.append("Hit count must be 1–100")
	if not is_finite(required_charge) or required_charge < 0 or not is_finite(minimum_magnitude) or minimum_magnitude < 0: errors.append("Rule thresholds must be finite and nonnegative")
	return errors
