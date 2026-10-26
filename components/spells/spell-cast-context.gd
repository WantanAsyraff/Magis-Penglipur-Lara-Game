class_name SpellCastContext extends RefCounted

static var _next_id: int = 0
var cast_id: int
var caster: Node2D
var spell: SpellData
var source_position: Vector2
var direction: Vector2 = Vector2.RIGHT
var targets: Array[Node2D] = []
var modifiers: Dictionary = {}
var source_team: StringName
var timestamp_msec: int
var chain_depth: int = 0
var remaining_effect_budget: int = 256
var state: Dictionary = {}
var cancelled: bool = false

func _init(actor: Node2D = null, definition: SpellData = null) -> void:
	_next_id += 1
	cast_id = _next_id
	caster = actor
	spell = definition
	timestamp_msec = Time.get_ticks_msec()
	if is_instance_valid(actor):
		source_position = actor.global_position
		source_team = &"player" if actor.is_in_group("player") else &"enemy"

func can_execute() -> bool:
	return not cancelled and is_instance_valid(caster) and not caster.is_queued_for_deletion() and remaining_effect_budget > 0 and chain_depth <= 8
