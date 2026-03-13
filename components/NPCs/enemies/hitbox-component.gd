# HitboxComponent.gd
class_name HitboxComponent
extends Node

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal damage_taken(amount: float)
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
## Set false for destructables.
@export var receives_status_effects: bool = true

## If true, this entity has a mana pool that can be drained.
@export var has_mana: bool = false

## If true, knockback is applied to the parent's velocity.
@export var receives_knockback: bool = true

## Multiplier for all incoming damage. Use for resistances or weaknesses.
@export var damage_multiplier: float = 1.0

## Flat damage reduction applied before multiplier.
@export var damage_reduction: float = 0.0

# ─────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────
var _active_effects: Dictionary = {}
var _is_stunned: bool = false
var _is_silenced: bool = false
var _slow_factor: float = 0.0

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
	if _parent is CharacterBody2D:
		_character_body = _parent

func _physics_process(delta: float) -> void:
	_tick_effects(delta)

# ─────────────────────────────────────────
# PRIMARY ENTRY POINT
# ─────────────────────────────────────────

## Call this from a projectile or AOE when it hits this entity.
## Pass the SpellData and the normalised direction the spell came from.
func receive_hit(spell: SpellData, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if spell == null:
		return

	if spell.projectile_damage > 0.0:
		_apply_damage(spell.projectile_damage)

	if receives_knockback and spell.knockback_force > 0.0:
		_apply_knockback(hit_direction, spell.knockback_force)

	if not receives_status_effects:
		return

	if spell.stunnable and spell.stun_dur > 0.0:
		_apply_stun(spell.stun_dur)

	if spell.applies_slow and spell.slow_factor > 0.0:
		_apply_slow(spell.slow_factor, spell.slow_duration)

	if spell.dot and spell.dot_duration > 0.0:
		_apply_dot(spell.dot_damage, spell.dot_interval, spell.dot_duration)

	if has_mana and spell.applies_mana_drain and spell.mana_drain_amount > 0.0:
		_apply_mana_drain(spell.mana_drain_amount, spell.mana_drain_duration)

	if spell.applies_silence and spell.silence_duration > 0.0:
		_apply_silence(spell.silence_duration)

# ─────────────────────────────────────────
# STATUS QUERIES
# ─────────────────────────────────────────

## Returns true if entity cannot move.
func is_stunned() -> bool:
	return _is_stunned

## Returns true if entity cannot cast.
func is_silenced() -> bool:
	return _is_silenced

## Returns current slow factor (0.0 = no slow, 1.0 = full root).
func get_slow_factor() -> float:
	return _slow_factor

# ─────────────────────────────────────────
# EFFECT APPLICATORS
# ─────────────────────────────────────────
func _apply_damage(raw_damage: float) -> void:
	var final_damage := maxf((raw_damage - damage_reduction) * damage_multiplier, 0.0)
	damage_taken.emit(final_damage)

	if _parent.get("current_health") != null:
		_parent.current_health -= final_damage
		if _parent.current_health <= 0.0:
			_parent.current_health = 0.0
			died.emit()

func _apply_knockback(direction: Vector2, force: float) -> void:
	if _character_body == null or direction == Vector2.ZERO:
		return
	var kb := direction.normalized() * force
	_character_body.velocity += kb
	knocked_back.emit(kb)

func _apply_stun(duration: float) -> void:
	_active_effects["stun"] = {
		"timer": duration,
		"data": {}
	}
	_is_stunned = true
	status_applied.emit("stun")

func _apply_slow(factor: float, duration: float) -> void:
	var existing_factor := 0.0
	if _active_effects.has("slow"):
		existing_factor = _active_effects["slow"]["data"]["factor"]
	_active_effects["slow"] = {
		"timer": duration,
		"data": { "factor": maxf(factor, existing_factor) }
	}
	_slow_factor = _active_effects["slow"]["data"]["factor"]
	status_applied.emit("slow")

func _apply_dot(damage: float, interval: float, duration: float) -> void:
	_active_effects["dot"] = {
		"timer": duration,
		"tick_timer": interval,
		"data": { "damage": damage, "interval": interval }
	}
	status_applied.emit("dot")

func _apply_mana_drain(amount: float, duration: float) -> void:
	if not has_mana:
		return
	_active_effects["mana_drain"] = {
		"timer": duration,
		"tick_timer": 1.0,
		"data": { "amount": amount }
	}
	status_applied.emit("mana_drain")

func _apply_silence(duration: float) -> void:
	_active_effects["silence"] = {
		"timer": duration,
		"data": {}
	}
	_is_silenced = true
	status_applied.emit("silence")

# ─────────────────────────────────────────
# EFFECT TICK
# ─────────────────────────────────────────
func _tick_effects(delta: float) -> void:
	var expired: Array[String] = []

	for effect_name in _active_effects.keys():
		var effect: Dictionary = _active_effects[effect_name]
		effect["timer"] -= delta

		match effect_name:
			"dot":
				effect["tick_timer"] -= delta
				if effect["tick_timer"] <= 0.0:
					_apply_damage(effect["data"]["damage"])
					effect["tick_timer"] = effect["data"]["interval"]
			"mana_drain":
				effect["tick_timer"] -= delta
				if effect["tick_timer"] <= 0.0:
					_drain_mana(effect["data"]["amount"])
					effect["tick_timer"] = 1.0

		if effect["timer"] <= 0.0:
			expired.append(effect_name)

	for effect_name in expired:
		_expire_effect(effect_name)

func _expire_effect(effect_name: String) -> void:
	_active_effects.erase(effect_name)
	match effect_name:
		"stun":
			_is_stunned = false
		"slow":
			_slow_factor = 0.0
		"silence":
			_is_silenced = false
	status_expired.emit(effect_name)

func _drain_mana(amount: float) -> void:
	# Supports both PlayerGlobalData naming and generic NPC naming
	if _parent.get("p_curr_mana") != null:
		_parent.p_curr_mana = maxf(_parent.p_curr_mana - amount, 0.0)
	elif _parent.get("current_mana") != null:
		_parent.current_mana = maxf(_parent.current_mana - amount, 0.0)
	mana_drained.emit(amount)

# ─────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────

## Force-clear all active effects. Call on death or scene transition.
func clear_all_effects() -> void:
	_active_effects.clear()
	_is_stunned = false
	_is_silenced = false
	_slow_factor = 0.0

## Returns a read-only copy of active effects for UI or debug use.
func get_active_effects() -> Dictionary:
	return _active_effects.duplicate()
