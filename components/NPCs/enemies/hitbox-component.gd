# HitboxComponent.gd
class_name HitboxComponent
extends Node

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal damage_taken(amount: float)
signal hit_received(source: Node2D, amount: float)
signal healed(amount: float)
signal died()
signal status_applied(effect_name: String)
signal status_expired(effect_name: String)
signal mana_drained(amount: float)
signal knocked_back(force: Vector2)

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────
## If true, this entity can receive status effects (stun, slow, silence etc).
@export var receives_status_effects: bool = true

## If true, this entity has a mana pool that can be drained.
@export var has_mana: bool = false

## If true, knockback is applied to the parent's velocity.
@export var receives_knockback: bool = true

## Multiplier for all incoming damage.
@export var damage_multiplier: float = 1.0

## Flat damage reduction applied before multiplier.
@export var damage_reduction: float = 0.0

# ─────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────
@export_range(0, 1) var knockback_resistance: float = 0.0
@export var status_resistances: Dictionary[String, float] = {}

var effects := ActiveEffectManager.new()
var _invincible: bool = false

# ─────────────────────────────────────────
# REFERENCES
# ─────────────────────────────────────────
var _parent: Node = null
var _character_body: CharacterBody2D = null

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_parent = get_parent()
	_parent.add_to_group("combat_target")
	_create_feedback.call_deferred()
	add_to_group("hitbox")
	add_to_group("ally_hitbox" if _parent is Player else "enemy_hitbox")
	effects.applied.connect(status_applied.emit)
	effects.expired.connect(status_expired.emit)
	effects.periodic.connect(_on_periodic)
	if _parent is CharacterBody2D:
		_character_body = _parent

func _physics_process(delta: float) -> void:
	if SpellExecutor.is_authoritative(self):
		effects.tick(delta)

# ─────────────────────────────────────────
# PRIMARY ENTRY POINT
# ─────────────────────────────────────────
func receive_hit(spell: SpellData, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if spell == null or _invincible or not SpellExecutor.is_authoritative(self):
		return
	# Public legacy API: direct callers still receive the same adapter payload.
	var context := SpellCastContext.new(_parent as Node2D, spell)
	context.direction = hit_direction
	SpellExecutor.new().execute(context, _parent as Node2D)

# ─────────────────────────────────────────
# STATUS QUERIES
# ─────────────────────────────────────────
func is_stunned() -> bool:
	return effects.has("stun")

func is_silenced() -> bool:
	return effects.has("silence")

func get_slow_factor() -> float:
	var factor := 0.0
	for entry in effects.entries:
		if entry.key == "slow":
			factor = maxf(factor, entry.data.get("factor", 0.0))
	return clampf(factor, 0.0, 1.0)

func is_invincible() -> bool:
	return _invincible

func set_invincible(value: bool) -> void:
	_invincible = value
	# Clear any active debuffs when turning invincibility on — no point keeping
	# stun/slow/silence if god mode just activated
	if _invincible:
		clear_all_effects()

# ─────────────────────────────────────────
# EFFECT APPLICATORS
# ─────────────────────────────────────────
func _apply_damage(raw_damage: float) -> void:
	receive_damage(raw_damage)

func receive_damage(raw_damage: float, source: Node2D = null) -> void:
	if _invincible or not SpellExecutor.is_authoritative(self) or get_parent().get_meta("combat_dead", false):
		return
	if not is_finite(raw_damage) or raw_damage < 0: return
	var final_damage := maxf((raw_damage - damage_reduction - effects.magnitude("buff_defense")) * damage_multiplier, 0.0)
	hit_received.emit(source, final_damage)
	damage_taken.emit(final_damage)

func _apply_knockback(direction: Vector2, force: float) -> void:
	if _invincible or not SpellExecutor.is_authoritative(self) or get_parent().get_meta("combat_dead", false):
		return
	if _character_body == null or direction == Vector2.ZERO:
		return
	var kb := direction.normalized() * force * (1.0 - knockback_resistance)
	_character_body.velocity += kb
	knocked_back.emit(kb)

func _apply_stun(duration: float) -> void:
	apply_status("stun", duration, {}, "", ActiveEffectManager.StackPolicy.REFRESH, 1)
func _apply_slow(factor: float, duration: float) -> void:
	apply_status("slow", duration, {"factor": clampf(maxf(factor, get_slow_factor()), 0.0, 1.0)}, "", ActiveEffectManager.StackPolicy.REFRESH, 1)
func _apply_dot(damage: float, interval: float, duration: float) -> void:
	apply_status("dot", duration, {"amount": damage, "interval": interval}, "", ActiveEffectManager.StackPolicy.REFRESH, 1)
func _apply_mana_drain(amount: float, duration: float) -> void:
	if has_mana:
		apply_status("mana_drain", duration, {"amount": amount}, "", ActiveEffectManager.StackPolicy.REFRESH, 1)
func _apply_silence(duration: float) -> void:
	apply_status("silence", duration, {}, "", ActiveEffectManager.StackPolicy.REFRESH, 1)
func _on_periodic(key: String, data: Dictionary) -> void:
	if not is_instance_valid(_parent) or _parent.is_queued_for_deletion():
		return
	match key:
		"dot": _apply_damage(data.get("amount", 0.0))
		"mana_drain": mana_drained.emit(data.get("amount", 0.0))
		"hot": healed.emit(data.get("amount", 0.0))
func clear_all_effects() -> void:
	effects.clear()
func get_active_effects() -> Dictionary:
	return effects.snapshot()
func remove_effect(effect_name: String) -> void:
	effects.remove(effect_name)
func clear_all_debuffs() -> void:
	effects.clear(0)
func clear_all_buffs() -> void:
	effects.clear(1)

func _create_feedback() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(_parent) or _parent.is_queued_for_deletion(): return
	var feedback := SpellStatusFeedback.new()
	feedback.hitbox = self
	_parent.add_child(feedback)

func apply_status(key: String, duration: float, data: Dictionary, source: String, policy: ActiveEffectManager.StackPolicy, max_stacks: int) -> bool:
	if not receives_status_effects or _invincible or get_parent().get_meta("combat_dead", false) or not SpellExecutor.is_authoritative(self): return false
	if key == "mana_drain" and not has_mana: return false
	var resistance := clampf(status_resistances.get(key, 0.0), 0, 1)
	if resistance >= 1: return false
	return effects.apply(key, duration * (1 - resistance), data, source, policy, max_stacks)
