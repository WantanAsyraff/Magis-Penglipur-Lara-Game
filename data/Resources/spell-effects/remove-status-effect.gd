class_name RemoveStatusEffect extends SpellEffectDefinition
@export var status: String = ""
@export var remove_buffs: bool = false
@export var remove_debuffs: bool = true

func execute(_context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if not status.is_empty():
		h.remove_effect(status)
	if remove_buffs:
		h.clear_all_buffs()
	if remove_debuffs:
		h.clear_all_debuffs()
	return true
