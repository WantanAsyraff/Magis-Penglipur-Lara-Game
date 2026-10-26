class_name RemoveStatusEffect extends SpellEffectDefinition
@export var respect_teams: bool = false
@export var status: String = ""
@export var remove_buffs: bool = false
@export var remove_debuffs: bool = true

func execute(context: SpellCastContext, target: Node2D) -> bool:
	var h: HitboxComponent = target.get_node("HitboxComponent")
	if not status.is_empty():
		h.remove_effect(status)
	var team: StringName = target.get_meta("spell_team", &"player" if target.is_in_group("player") else &"enemy")
	var ally := team == context.source_team
	if remove_buffs and (not respect_teams or not ally):
		h.clear_all_buffs()
	if remove_debuffs and (not respect_teams or ally):
		h.clear_all_debuffs()
	return true
