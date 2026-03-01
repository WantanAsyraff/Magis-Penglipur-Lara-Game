class_name NpcSpellHandler
extends Node

# ─────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────
signal spell_cast(spell: SpellData)
signal mana_changed(current: float, max: float)
signal mana_depleted

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var current_mana: float
var is_casting: bool = false
var regen_timer: float = 0.0
var cast_cooldown_timer: float = 0.0

var _npc: SpellCasterNPC
var _data: NPCSpellcasterData

const PROJECTILE_SCENE = preload("res://components/projectiles/magis-projectile.tscn")

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_npc = get_parent() as SpellCasterNPC
	_data = _npc.data
	current_mana = _data.max_mana

func _process(delta: float) -> void:
	_tick_cooldown(delta)
	_tick_mana_regen(delta)

# ─────────────────────────────────────────
# CASTING
# ─────────────────────────────────────────
func try_cast(spell: SpellData) -> bool:
	if is_casting:
		return false
	if current_mana < spell.upfront_cost:
		return false
	if cast_cooldown_timer > 0.0:
		return false

	is_casting = true
	current_mana -= spell.upfront_cost
	mana_changed.emit(current_mana, _data.max_mana)

	# Wait for cast_time then fire
	await get_tree().create_timer(spell.cast_time).timeout
	_fire(spell)

	is_casting = false
	cast_cooldown_timer = randf_range(_data.cast_delay_min, _data.cast_delay_max)
	return true

func _fire(spell: SpellData) -> void:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.spell_data = spell

	# Aim at player
	var player = _npc.player
	if player:
		var dir = (player.global_position - _npc.global_position).normalized()
		projectile.direction = dir

	projectile.position = _npc.global_position
	get_tree().current_scene.add_child(projectile)
	spell_cast.emit(spell)

# ─────────────────────────────────────────
# MANA
# ─────────────────────────────────────────
func _tick_mana_regen(delta: float) -> void:
	if is_casting:
		regen_timer = _data.mana_regen_delay
		return

	if regen_timer > 0.0:
		regen_timer -= delta
		return

	if current_mana < _data.max_mana:
		current_mana = minf(current_mana + _data.mana_regen_rate * delta, _data.max_mana)
		mana_changed.emit(current_mana, _data.max_mana)

func _tick_cooldown(delta: float) -> void:
	if cast_cooldown_timer > 0.0:
		cast_cooldown_timer -= delta

# ─────────────────────────────────────────
# QUERIES  (brain reads these)
# ─────────────────────────────────────────
func is_low_mana() -> bool:
	return current_mana / _data.max_mana <= _data.low_mana_threshold

func is_ready_to_cast() -> bool:
	return not is_casting and cast_cooldown_timer <= 0.0 and not is_low_mana()

func get_affordable_spells() -> Array[SpellData]:
	var affordable: Array[SpellData] = []
	for spell in _data.spell_pool:
		if current_mana >= spell.upfront_cost:
			affordable.append(spell)
	return affordable
