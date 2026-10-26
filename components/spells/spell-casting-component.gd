class_name SpellCastingComponent extends Node
enum State { IDLE, PREPARING, CHANNELING, EXECUTING, RECOVERY }
signal state_changed(state: State)
signal cast_failed(reason: String)
signal cast_completed(context: SpellCastContext)
var state: State = State.IDLE
var caster: Node2D
var context: SpellCastContext
var cooldowns: Dictionary = {}
var remaining: float = 0.0
var _paid_upfront: float = 0.0

func _ready() -> void:
	caster = get_parent() as Node2D

func _set_state(value: State) -> void:
	state = value
	state_changed.emit(state)

func request_cast(spell: SpellData, origin: Vector2, direction: Vector2, targets: Array[Node2D] = []) -> bool:
	if state != State.IDLE:
		return _fail("Already casting")
	if spell == null or not SpellExecutor.is_authoritative(caster):
		return _fail("Casting requires gameplay authority")
	var errors := SpellValidator.validate(spell)
	if not errors.is_empty():
		return _fail(errors[0])
	if caster.has_method("can_cast_spell") and not caster.can_cast_spell(spell):
		return _fail("Spell is not learned and equipped")
	if _restricted():
		return _fail("Silenced or stunned")
	if cooldowns.get(spell.spell_id, 0.0) > 0:
		return _fail("Spell is cooling down")
	if direction == Vector2.ZERO or not direction.is_finite() or not origin.is_finite():
		return _fail("Invalid cast direction or origin")
	if LegacySpellAdapter.delivery_for(spell) == SpellData.Delivery.DIRECT_TARGET:
		if targets.is_empty() or not is_instance_valid(targets[0]) or targets[0].global_position.distance_to(caster.global_position) > spell.target_range:
			return _fail("Invalid target")
	if not caster.has_method("consume_spell_mana") or not caster.consume_spell_mana(spell.upfront_cost):
		return _fail("Not enough mana")
	_paid_upfront = spell.upfront_cost
	context = SpellCastContext.new(caster, spell)
	context.source_position = origin
	context.direction = direction.normalized()
	context.targets = targets.duplicate()
	var h := caster.get_node_or_null("HitboxComponent") as HitboxComponent
	if h:
		context.modifiers.damage = h.effects.magnitude("buff_damage")
	remaining = spell.cast_time / maxf(0.1, 1.0 + (h.effects.magnitude("buff_cast_speed") if h else 0.0))
	_set_state(State.PREPARING)
	if remaining <= 0:
		_finish_preparation()
	return true

func _physics_process(delta: float) -> void:
	for id in cooldowns.keys():
		cooldowns[id] = maxf(cooldowns[id] - delta, 0)
	if state == State.IDLE:
		return
	if not is_instance_valid(caster) or caster.is_queued_for_deletion() or _restricted() or not SpellExecutor.is_authoritative(caster):
		cancel("Cast interrupted")
		return
	if state == State.CHANNELING:
		var active_delta := minf(delta, remaining)
		if not caster.consume_spell_mana(context.spell.mana_per_second * active_delta):
			cancel("Not enough mana to channel")
			return
	remaining -= delta
	if remaining > 0:
		return
	match state:
		State.PREPARING:
			_finish_preparation()
		State.CHANNELING:
			_execute()
		State.RECOVERY:
			_set_state(State.IDLE)

func _finish_preparation() -> void:
	if context.spell.is_channelled and context.spell.channel_duration > 0:
		remaining = context.spell.channel_duration
		_set_state(State.CHANNELING)
	else:
		_execute()

func _execute() -> void:
	if LegacySpellAdapter.delivery_for(context.spell) == SpellData.Delivery.DIRECT_TARGET:
		if context.targets.is_empty() or not is_instance_valid(context.targets[0]) or context.targets[0].is_queued_for_deletion() or context.targets[0].global_position.distance_to(caster.global_position) > context.spell.target_range:
			cancel("Target lost during preparation")
			return
	_set_state(State.EXECUTING)
	if not SpellDelivery.dispatch(context):
		cancel("Spell delivery failed")
		return
	_paid_upfront = 0
	cooldowns[context.spell.spell_id] = context.spell.cooldown
	cast_completed.emit(context)
	remaining = context.spell.recovery_time
	_set_state(State.RECOVERY)
	if remaining <= 0:
		_set_state(State.IDLE)

func cancel(reason: String = "Cancelled") -> void:
	if state == State.IDLE:
		return
	# Refund upfront cost only before successful dispatch; spent channel mana is never refunded.
	if _paid_upfront > 0 and is_instance_valid(caster):
		caster.restore_spell_mana(_paid_upfront)
	_paid_upfront = 0
	if context and state != State.RECOVERY:
		context.cancelled = true
	_set_state(State.IDLE)
	cast_failed.emit(reason)

func _restricted() -> bool:
	var h := caster.get_node_or_null("HitboxComponent") as HitboxComponent
	return h != null and (h.is_stunned() or h.is_silenced())

func _fail(reason: String) -> bool:
	cast_failed.emit(reason)
	return false
