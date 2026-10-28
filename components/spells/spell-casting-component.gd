class_name SpellCastingComponent extends Node
enum State { IDLE, PREPARING, CHANNELING, EXECUTING, RECOVERY }
enum RequestStatus { RECOGNIZED, QUEUED, PREPARING, CHANNELING, EXECUTING, COMPLETED, FAILED, INTERRUPTED, CANCELLED }
signal request_status(request_id: int, chain_id: int, spell: SpellData, status: RequestStatus, reason: String)
var _next_request_id: int = 0
var _attempt: Dictionary = {}
var _active: Dictionary = {}

signal state_changed(state: State)
signal cast_failed(reason: String)
signal cast_completed(context: SpellCastContext)
## Player chains skip post-dispatch recovery; enemies retain authored pacing.
var immediate_chaining: bool = false
var previous_spell: SpellData
var previous_targets: Array[Node2D] = []
var live_delivery: SpellAreaDelivery
var state: State = State.IDLE
var caster: Node2D
var context: SpellCastContext
var cooldowns: Dictionary = {}
var remaining: float = 0.0
var _paid_upfront: float = 0.0
var _queue: Array[Dictionary] = []

func _ready() -> void:
	caster = get_parent() as Node2D

func _set_state(value: State) -> void:
	state = value
	state_changed.emit(state)
	var statuses := {State.PREPARING: RequestStatus.PREPARING, State.CHANNELING: RequestStatus.CHANNELING, State.EXECUTING: RequestStatus.EXECUTING}
	if statuses.has(state) and not _active.is_empty(): _report(_active, statuses[state])

func request_cast(spell: SpellData, origin: Vector2, direction: Vector2, targets: Array[Node2D] = [], chain_id: int = 0) -> bool:
	return _start(_new_request(spell, origin, direction, targets, chain_id))

func _start(request: Dictionary) -> bool:
	_attempt = request
	var spell: SpellData = request.spell
	var origin: Vector2 = request.origin
	var direction: Vector2 = request.direction
	var targets: Array[Node2D] = request.targets
	if state != State.IDLE:
		return _fail("Already casting")
	if spell == null or not is_instance_valid(caster) or caster.is_queued_for_deletion() or caster.get_meta("combat_dead", false) or not SpellExecutor.is_authoritative(caster):
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
	_active = request
	SpellFeedback.flash(caster, spell.spell_colour)
	_paid_upfront = spell.upfront_cost
	context = SpellCastContext.new(caster, spell)
	context.request_id = request.id
	context.incantation_chain_id = request.chain
	context.source_position = origin
	context.direction = direction.normalized()
	context.targets = targets.duplicate()
	if spell.delivery == SpellData.Delivery.AREA_BURST: context.source_position = caster.global_position
	if spell.aim_placement:
		context.source_position = caster.global_position + context.direction * minf(spell.target_range, 220)

	if caster.has_method("aim_locked_cast"): caster.aim_locked_cast(context)
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
		_drain_queue()
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
	_drain_queue()

func _drain_queue() -> void:
	# Bound work even if callbacks append new requests. Failed requests never stall the queue.
	var budget := 8
	while state == State.IDLE and not _queue.is_empty() and budget > 0:
		budget -= 1
		_start(_queue.pop_front())

func _finish_preparation() -> void:
	if caster.has_method("aim_locked_cast"): caster.aim_locked_cast(context)
	if context.spell.is_channelled and context.spell.channel_duration > 0:
		remaining = context.spell.channel_duration
		_set_state(State.CHANNELING)
		if context.spell.live_channel:
			if not (is_instance_valid(live_delivery) or SpellDelivery.dispatch(context)): cancel("Channel delivery failed"); return
			live_delivery = caster.get_parent().get_children().back() as SpellAreaDelivery
			_paid_upfront = 0
			cooldowns[context.spell.spell_id] = context.spell.cooldown

	else:
		_execute()

func _execute() -> void:
	if caster.has_method("aim_locked_cast"): caster.aim_locked_cast(context)
	if LegacySpellAdapter.delivery_for(context.spell) == SpellData.Delivery.DIRECT_TARGET:
		if context.targets.is_empty() or not is_instance_valid(context.targets[0]) or context.targets[0].is_queued_for_deletion() or context.targets[0].global_position.distance_to(caster.global_position) > context.spell.target_range:
			cancel("Target lost during preparation")
			return
	_set_state(State.EXECUTING)
	if not (is_instance_valid(live_delivery) or SpellDelivery.dispatch(context)):
		cancel("Spell delivery failed")
		return
	if is_instance_valid(live_delivery): live_delivery.queue_free()
	live_delivery = null
	if echo_eligible(context.spell):
		previous_spell = context.spell
		previous_targets = context.targets.duplicate()
	_paid_upfront = 0
	cooldowns[context.spell.spell_id] = context.spell.cooldown
	QuestEventHooks.cast(context)
	_report(_active, RequestStatus.COMPLETED)
	_active = {}
	cast_completed.emit(context)
	remaining = 0.0 if immediate_chaining else context.spell.recovery_time
	_set_state(State.RECOVERY)
	if remaining <= 0:
		_set_state(State.IDLE)

func cancel(reason: String = "Cancelled") -> void:
	for request in _queue: _report(request, RequestStatus.CANCELLED, reason)
	_queue.clear()
	if not _active.is_empty():
		_report(_active, RequestStatus.CANCELLED if reason == "Cancelled" else RequestStatus.INTERRUPTED, reason)
		_active = {}
	if is_instance_valid(live_delivery): live_delivery.queue_free()
	live_delivery = null
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
	_report(_attempt, RequestStatus.FAILED, reason)
	cast_failed.emit(reason)
	return false

func _new_request(spell: SpellData, origin: Vector2, direction: Vector2, targets: Array[Node2D], chain_id: int) -> Dictionary:
	_next_request_id += 1
	var request := {"id": _next_request_id, "chain": chain_id, "spell": spell, "origin": origin, "direction": direction, "targets": targets.duplicate()}
	_report(request, RequestStatus.RECOGNIZED)
	return request

func _report(request: Dictionary, status: RequestStatus, reason: String = "") -> void:
	if not request.is_empty(): request_status.emit(request.id, request.chain, request.spell, status, reason)

func enqueue_cast(spell: SpellData, origin: Vector2, direction: Vector2, targets: Array[Node2D] = [], chain_id: int = 0) -> bool:
	var request := _new_request(spell, origin, direction, targets, chain_id)
	if state == State.IDLE and _queue.is_empty():
		return _start(request)
	if _queue.size() >= 8:
		_attempt = request
		return _fail("Cast queue is full")
	_queue.append(request)
	_report(request, RequestStatus.QUEUED)
	return true

func _exit_tree() -> void:
	cancel("Caster removed")

# Advisory only: actual authorization and payment remain in _start().
func preview_restriction(spell: SpellData, mana: float) -> String:
	if not is_instance_valid(caster) or not SpellExecutor.is_authoritative(caster): return "No gameplay authority"
	if _restricted(): return "Silenced or stunned"
	if caster.has_method("can_cast_spell") and not caster.can_cast_spell(spell): return "Not equipped"
	var cooldown: float = cooldowns.get(spell.spell_id, 0.0)
	if cooldown > 0: return "Ready in %.1fs" % cooldown
	if mana < spell.upfront_cost: return "Insufficient mana"
	return "Ready (preview)"

static func echo_eligible(spell: SpellData) -> bool:
	if LegacySpellAdapter.delivery_for(spell) not in [SpellData.Delivery.PROJECTILE, SpellData.Delivery.SELF, SpellData.Delivery.DIRECT_TARGET, SpellData.Delivery.AREA_BURST]: return false
	for effect in LegacySpellAdapter.effects_for(spell):
		if not (effect is DamageEffect or effect is HealEffect or effect is KnockbackEffect or effect is ApplyStatusEffect): return false
	return true
