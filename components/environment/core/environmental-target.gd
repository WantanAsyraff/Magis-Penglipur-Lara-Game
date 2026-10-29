class_name EnvironmentalTarget extends Node
@export var targetable: bool = true
@export var accept_hostile_spells: bool = false
func _ready() -> void:
	get_parent().add_to_group("environmental_targets")
func can_receive(context: SpellCastContext) -> bool:
	return targetable and not get_parent().get_meta("combat_dead",false) and (accept_hostile_spells or context.source_team == &"player")
