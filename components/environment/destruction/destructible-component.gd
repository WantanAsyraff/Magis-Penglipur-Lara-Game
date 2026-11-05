class_name DestructibleComponent extends Node
signal damage_received(amount: float, damage: EnvironmentalDamage)
signal health_changed(current: float, maximum: float)
signal state_changed(previous: DestructibleStateDefinition, current: DestructibleStateDefinition)
signal destruction_started(context: DestructionContext)
signal destroyed(context: DestructionContext)
signal destruction_completed(context: DestructionContext)
signal repaired(amount: float)
signal authored_event(event_id: StringName, context: DestructionContext)
@export var config: DestructibleConfig
var health := 0.0
var current_state: DestructibleStateDefinition
var effects_executed := false
var animation_in_progress := false
var generation := 0
var _destroyed := false
var _completion_emitted := false
var _elapsed := 0.0
var _context: DestructionContext
var runtime: DestructionRuntime
var object: Node2D
var _persistence_allowed := true
func _ready() -> void:
	object = get_parent() as Node2D
	if config == null: config = object.get("config") as DestructibleConfig
	if config == null: push_warning("Destructible has no configuration"); return
	runtime = DestructionRuntime.for_object(object)
	if DestructiblePersistence.enabled(config):
		var existing: Variant = runtime.persistent_ids.get(config.persistence_id)
		if existing != null and is_instance_valid(existing.get_ref()):
			push_warning("Duplicate persistent destructible ID: " + config.persistence_id); _persistence_allowed = false
		else: runtime.persistent_ids[config.persistence_id] = weakref(self)
	var hitbox := object.get_node_or_null("HitboxComponent") as DestructibleHitbox
	if hitbox:
		hitbox.hit_received.connect(_hit_received)
		hitbox.healed.connect(repair)
		if config.material: hitbox.knockback_resistance = config.material.knockback_resistance
	reset_destructible(false)
	var saved := DestructiblePersistence.restore(config) if _persistence_allowed else {}
	if not saved.is_empty():
		health = 0.0 if saved.destroyed else saved.health
		_destroyed = saved.destroyed; effects_executed = _destroyed; _completion_emitted = _destroyed
		object.set_meta("combat_dead", _destroyed)
		_transition(true)
		health_changed.emit(health, config.max_health)
		if _destroyed and config.remove_after_destroy: object.queue_free()
func _hit_received(source: Node2D, amount: float) -> void:
	var hitbox := object.get_node("HitboxComponent") as DestructibleHitbox
	var damage := hitbox.incoming
	if damage == null: damage = EnvironmentalDamage.new(); damage.instigator = source
	apply_damage(amount, damage)
func can_receive_damage() -> bool:
	return config != null and config.enabled and not config.invulnerable and not _destroyed and SpellExecutor.is_authoritative(self) and is_finite(config.max_health) and config.max_health > 0 and is_finite(config.damage_multiplier) and config.damage_multiplier >= 0 and (current_state == null or current_state.interaction_enabled)
func apply_damage(amount: float, damage: EnvironmentalDamage = null) -> bool:
	if not can_receive_damage() or not is_finite(amount) or amount <= 0: return false
	if damage == null: damage = EnvironmentalDamage.new()
	if damage.kind < 0 or damage.kind >= EnvironmentalDamage.Kind.size(): return false
	var multiplier := config.material.multiplier(damage.kind) if config.material else 1.0
	if not is_finite(multiplier) or multiplier < 0: return false
	var applied := minf(health, amount * config.damage_multiplier * multiplier)
	if not is_finite(applied) or applied <= 0: return false
	health -= applied
	damage_received.emit(applied, damage)
	if health <= 0 and config.destroy_on_zero_health: return destroy(damage)
	health_changed.emit(health, config.max_health)
	_transition()
	var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
	if visual:
		visual.play_hook(&"hit")
		if config.material: visual.feedback(config.material.default_damage_sound, config.material.default_impact_particles)
	_persist()
	return true
func repair(amount: float) -> bool:
	if config == null or not config.enabled or _destroyed or not SpellExecutor.is_authoritative(self) or not is_finite(amount) or amount <= 0: return false
	var restored := minf(amount, config.max_health - health)
	if restored <= 0: return false
	health += restored; _transition(); _persist()
	health_changed.emit(health, config.max_health); repaired.emit(restored)
	var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
	if visual: visual.play_hook(&"repair")
	return true
func set_health(value: float) -> bool:
	if not is_finite(value) or not can_receive_damage(): return false
	var target := clampf(value, 0, config.max_health)
	if target > health: return repair(target - health)
	if is_equal_approx(target, health): return false
	health = target
	if health <= 0 and config.destroy_on_zero_health: return destroy()
	_transition(); _persist(); health_changed.emit(health, config.max_health)
	return true
func destroy(damage: EnvironmentalDamage = null) -> bool:
	if config == null or not config.enabled or config.invulnerable or _destroyed or not SpellExecutor.is_authoritative(self): return false
	generation += 1; _destroyed = true; health = 0; effects_executed = false
	animation_in_progress = true; _elapsed = 0.0; _completion_emitted = false
	object.set_meta("combat_dead", true)
	_context = DestructionContext.new()
	_context.source = weakref(object); _context.source_id = config.destructible_id; _context.generation = generation
	_context.position = object.global_position; _context.material = config.material; _context.damage = damage
	_context.instigator = damage.instigator if damage else null
	_context.faction = CombatFactions.faction(_context.instigator) if is_instance_valid(_context.instigator) else CombatFactions.faction(object)
	_context.credit_owner = GameplayEvent.owner_for(_context.instigator)
	_context.spell = damage.spell_context.spell if damage and damage.spell_context else null
	var predecessor := damage.destruction_context if damage else (object.get_meta("destruction_parent_context") as DestructionContext if object.has_meta("destruction_parent_context") else null)
	_context.budget = predecessor.budget if predecessor else DestructionBudget.new()
	_context.depth = predecessor.depth + 1 if predecessor else 0
	_context.event_id = _context.budget.root_event_id + ":" + str(object.get_instance_id()) + ":" + str(generation)
	_context.rng.seed = hash(_context.event_id)
	_context.runtime = runtime; _context.authoritative = SpellExecutor.is_authoritative(self)
	_transition(); _persist()
	health_changed.emit(health, config.max_health)
	destruction_started.emit(_context); destroyed.emit(_context)
	var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
	if visual:
		visual.begin_destruction(config.destruction_seconds)
		if config.material: visual.feedback(config.material.default_break_sound, config.material.default_destroy_particles)
	if _context.budget.reserve_destruction(_context.depth): runtime.enqueue(_context, config.behaviors)
	else: effects_executed = true
	return true
func _physics_process(delta: float) -> void:
	if not _destroyed or _completion_emitted or _context == null: return
	_elapsed += delta
	animation_in_progress = _elapsed < config.destruction_seconds
	if not animation_in_progress and effects_executed:
		_completion_emitted = true
		var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
		if visual: visual.finish_destruction()
		destruction_completed.emit(_context)
		if config.remove_after_destroy: object.queue_free()
func behaviors_finished() -> void:
	effects_executed = true
func reset_destructible(write_persistence: bool = true) -> bool:
	if config == null or not SpellExecutor.is_authoritative(self): return false
	generation += 1; _destroyed = false; effects_executed = false; animation_in_progress = false; _completion_emitted = false; _context = null
	health = config.max_health * (config.initial_health_ratio if config.starts_damaged else 1.0)
	object.set_meta("combat_dead", false)
	var hitbox := object.get_node_or_null("HitboxComponent") as HitboxComponent
	if hitbox: hitbox.effects.clear()
	_transition(true); health_changed.emit(health, config.max_health)
	var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
	if visual: visual.play_hook(&"reset")
	if write_persistence: _persist()
	return true
func _transition(restoring: bool = false) -> void:
	var selected: DestructibleStateDefinition
	for state in config.states:
		if state != null and get_health_ratio() <= state.health_threshold_ratio and (selected == null or state.health_threshold_ratio < selected.health_threshold_ratio): selected = state
	var previous := current_state; current_state = selected
	var collision_enabled := not (_destroyed and config.collision_disabled_on_destroy)
	if selected: collision_enabled = collision_enabled and selected.collision_enabled
	for shape in object.find_children("*", "CollisionShape2D", true, false):
		if shape.get_parent() is PhysicsBody2D: shape.set_deferred("disabled", not collision_enabled)
	var target := object.get_node_or_null("EnvironmentalTarget") as EnvironmentalTarget
	if target: target.targetable = not _destroyed and config.enabled and (selected == null or selected.interaction_enabled)
	var visual := object.get_node_or_null("VisualRoot") as DestructibleVisualController
	if visual and (selected != previous or restoring): visual.present(selected, _destroyed, restoring)
	if selected != previous and not restoring: state_changed.emit(previous, selected)
func _persist() -> void:
	if _persistence_allowed: DestructiblePersistence.store(config, health, _destroyed)
func get_health_ratio() -> float:
	return clampf(health / maxf(config.max_health, 1.0), 0, 1) if config else 0.0
func get_current_state() -> DestructibleStateDefinition:
	return current_state
func is_destroyed() -> bool:
	return _destroyed
