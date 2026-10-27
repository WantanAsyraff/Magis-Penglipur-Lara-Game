class_name TriggerEffect extends SpellEffectDefinition
@export var duration: float = 4.0
@export_range(1, 6) var hits: int = 3
@export var children: Array[SpellEffectDefinition] = []
func validate() -> PackedStringArray:
	return PackedStringArray(["Invalid trigger lifetime or count"]) if duration <= 0 or duration > 30 or not is_finite(duration) or hits < 1 or hits > 6 else PackedStringArray()
func execute(context: SpellCastContext, target: Node2D) -> bool:
	for child in target.get_children():
		if child is SpellHitTrigger and child.context.spell.spell_id == context.spell.spell_id:
			child.queue_free()
	var trigger := SpellHitTrigger.new()
	trigger.context = context
	trigger.definition = self
	target.add_child(trigger)
	return true
