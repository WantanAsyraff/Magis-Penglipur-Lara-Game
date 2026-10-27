class_name SpellHitTrigger extends Node
var context: SpellCastContext
var definition: TriggerEffect
var elapsed: float = 0.0
var count: int = 0
var fired: bool = false
func _ready() -> void:
	get_parent().get_node("HitboxComponent").damage_taken.connect(_hit)
func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= definition.duration or not context.can_execute(): queue_free()
func _hit(amount: float) -> void:
	if fired or is_queued_for_deletion() or amount <= 0 or not context.can_execute(): return
	count += 1
	if count < definition.hits: return
	fired = true
	SpellExecutor.execute_effects(context, get_parent() as Node2D, definition.children)
	queue_free()
