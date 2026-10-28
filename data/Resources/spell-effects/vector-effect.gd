class_name VectorEffect extends SpellEffectDefinition
## Explicit capability tags opt environment objects into manipulation.
enum Mode { IMPULSE, ATTRACT, ORBIT, DAMP, LIFT }
@export var mode: Mode = Mode.IMPULSE
@export var strength: float = 180.0
@export var capability: StringName = &""
func accepts(target: Node2D) -> bool:
	return target is CharacterBody2D and (capability == &"" or target.has_meta(capability))
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid vector strength"]) if not is_finite(strength) or strength < 0 or strength > 2000 else PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	var body := target as CharacterBody2D
	var before := body.velocity
	var radial := (context.source_position - body.global_position).normalized()
	match mode:
		Mode.IMPULSE: body.velocity += context.direction * strength
		Mode.ATTRACT: body.velocity += radial * strength
		Mode.ORBIT: body.velocity += (radial + radial.orthogonal()) * strength
		Mode.DAMP: body.velocity *= clampf(1.0 - strength, 0, 1)
		Mode.LIFT: body.velocity.y = minf(body.velocity.y, -strength)
	body.velocity = body.velocity.limit_length(1800)
	if mode == Mode.DAMP: return true
	var motion := body.get_node_or_null("SpellMotionImpulse") as SpellMotionImpulse
	if motion == null:
		motion = SpellMotionImpulse.new()
		motion.name = "SpellMotionImpulse"
		body.add_child(motion)
	motion.impulse = (motion.impulse + body.velocity - before).limit_length(1000)
	motion.remaining = 0.25
	return true
