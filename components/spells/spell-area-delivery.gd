class_name SpellAreaDelivery extends Node2D
var context: SpellCastContext
var elapsed: float = 0.0
var until_tick: float = 0.0
func _physics_process(delta: float) -> void:
	if context == null or not context.can_execute():
		queue_free()
		return
	elapsed += delta
	until_tick -= delta
	if elapsed > context.spell.area_duration:
		queue_free()
		return
	if until_tick <= 0:
		until_tick += maxf(context.spell.area_tick_interval, 0.05)
		var delivery := LegacySpellAdapter.delivery_for(context.spell)
		var hit := SpellDelivery.apply_area(context, global_position, delivery == SpellData.Delivery.BEAM)
		if hit and delivery == SpellData.Delivery.TRAP:
			queue_free()
