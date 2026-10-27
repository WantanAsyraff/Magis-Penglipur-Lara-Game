# Player.gd
class_name Player
extends CharacterBody2D

# -------------------------
# CONSTANTS & SCENES
# -------------------------
const PROJECTILE_SCENE = preload("res://components/projectiles/magis-projectile.tscn")

const DIRECTION_ICONS := {
	"up":    "res://assets/ui/spells/casting-icon-up.png",
	"down":  "res://assets/ui/spells/casting-icon-down.png",
	"left":  "res://assets/ui/spells/casting-icon-left.png",
	"right": "res://assets/ui/spells/casting-icon-right.png",
}

@export var mana_regen_rate: float = 5.0
@export var combat_mode: bool = false:
	set(value):
		combat_mode = value
		if (not is_inside_tree() or is_multiplayer_authority()) and Player_Global_Data.combat_mode != value:
			Player_Global_Data.combat_mode = value
		_on_combat_mode_changed(value)

@export var parry_particles_scene: PackedScene
@export var block_particles_scene: PackedScene

@onready var castMarker: Marker2D = %CastDirectionMarker
@onready var spell_label: Label = %castingText
@onready var spell_icon_box: HBoxContainer = %SpellIconBox
@onready var camera: Camera2D = %Camera2D
@onready var dash_particles: GPUParticles2D = %DashParticles
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var stop_label: Label = %StopLabel

# -------------------------
# VARIABLES
# -------------------------
var SPEED : float = Player_Global_Data.p_speed
var JUMP_VELOCITY : float = Player_Global_Data.p_jump_height

# Dash — charge based
var DASH_SPEED : float = 3400.0
var DASH_TIME : float = 0.18
var DASH_COOLDOWN : float = 1.2
var max_dashes = Player_Global_Data.MAX_DASH_CHARGES

var dash_timer : float = 0.0
var dash_direction := Vector2.ZERO

var is_dashing := false:
	set(value):
		is_dashing = value
		if is_multiplayer_authority():
			Player_Global_Data.is_dashing = value

var dash_charges: int = Player_Global_Data.MAX_DASH_CHARGES:
	set(value):
		dash_charges = clampi(value, 0, get_max_dash_charges())
		if is_multiplayer_authority():
			Player_Global_Data.current_dash_charges = dash_charges
var dash_regen_timer := 0.0

# Spells
@export var incantation_strategy: IncantationResolver.Strategy = IncantationResolver.Strategy.CHAINED
var casting: SpellCastingComponent
var incantations := IncantationResolver.new()
var _remote_health: float = 100.0
var _remote_mana: float = 400.0
var spell_inventory: Array[SpellData] = []
var spell_string: Array[String] = []

# Casting stance — stays open until toggled off
var _in_casting_stance: bool = false

# Aim lock — true while held during casting stance
var _aim_locked: bool = false

# Ladder
const CLIMB_SPEED: float = 1500.0
var _climbing: bool = false

# Jump — coyote time & input buffering
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false

# Stop movement toggle
var _stop_moving_locked: bool = false

# -------------------------
# BLOCK / PARRY
# -------------------------
const PARRY_WINDOW: float = 0.18
const BLOCK_HP_COST_FRACTION: float  = 0.05
const BLOCK_MANA_COST_FRACTION: float = 0.05

var _is_blocking: bool = false
var _parry_timer: float  = 0.0
var _parry_active: bool  = false

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	add_to_group("player")
	casting = SpellCastingComponent.new()
	add_child(casting)
	casting.cast_failed.connect(_on_cast_failed)
	hitbox.status_applied.connect(func(key):
		if key == "buff_dash_charges":
			dash_charges = get_max_dash_charges())
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		set_process_unhandled_input(false)
		hitbox.has_mana = true
		hitbox.died.connect(_on_died)
		hitbox.damage_taken.connect(_on_damage_taken)
		hitbox.healed.connect(restore_spell_health)
		hitbox.mana_drained.connect(_on_mana_drained)
		return
	_sync_spells_from_global()
	Player_Global_Data.combat_mode_changed.connect(func(new_val): combat_mode = new_val)

	if Player_Global_Data.has_signal("spells_updated"):
		Player_Global_Data.spells_updated.connect(_sync_spells_from_global)

	combat_mode = Player_Global_Data.combat_mode
	Player_Global_Data.current_dash_charges = dash_charges

	hitbox.receives_status_effects = true
	hitbox.has_mana = true
	hitbox.receives_knockback = true
	hitbox.damage_taken.connect(_on_damage_taken)
	hitbox.healed.connect(restore_spell_health)
	hitbox.died.connect(_on_died)
	hitbox.status_applied.connect(_on_status_applied)
	hitbox.status_expired.connect(_on_status_expired)
	hitbox.mana_drained.connect(_on_mana_drained)
	hitbox.knocked_back.connect(_on_knocked_back)

	if stop_label:
		stop_label.visible = false

# -------------------------
# LOGIC: PHYSICS & MOVEMENT
# -------------------------
func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
	var delayed := incantations.tick(delta)
	if delayed:
		_cast_resolved(delayed)
	_handle_dash_timers(delta)
	_handle_jump_timers(delta)
	_handle_block_timers(delta)
	_update_aim_direction()
	_regen_mana(delta)

	if hitbox.is_stunned():
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if not Player_Global_Data.p_moveable:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return

	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return

	if _update_climbing():
		move_and_slide()
		return

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		_apply_gravity(delta)
		_handle_movement()

	move_and_slide()

func _handle_movement() -> void:
	if _aim_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		_try_jump()
		return

	var current_speed := (SPEED + hitbox.effects.magnitude("buff_speed")) * (1.0 - hitbox.get_slow_factor())
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0:
		velocity.x = dir * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	_try_jump()

func _try_jump() -> void:
	if _jump_buffer_timer > 0.0 and (_coyote_timer > 0.0 or is_on_floor()):
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

func _handle_combat_input() -> void:
	move_and_slide()

func _process_incantation_inputs() -> void:
	if hitbox.is_stunned() or hitbox.is_silenced():
		return

	if Input.is_action_just_pressed("clear_incantation"):
		_clear_sequence()
		return

	var pressed := ""
	if Input.is_action_just_pressed("incantation_up"):    pressed = "up"
	elif Input.is_action_just_pressed("incantation_down"):  pressed = "down"
	elif Input.is_action_just_pressed("incantation_left"):  pressed = "left"
	elif Input.is_action_just_pressed("incantation_right"): pressed = "right"

	if pressed == "":
		return

	var candidate := spell_string + [pressed]
	if not _has_partial_match(candidate):
		_fail_cast("No match!")
		return

	_add_sequence(pressed)

# -------------------------
# LADDER
# -------------------------
func _update_climbing() -> bool:
	var on_ladder: bool = has_meta("on_ladder")

	if not on_ladder:
		if _climbing:
			_climbing = false
		return false

	if Input.is_action_just_pressed("jump"):
		_climbing = false
		remove_meta("on_ladder")
		velocity.y = JUMP_VELOCITY
		return false

	var up := Input.is_action_pressed("climb_up")
	var down := Input.is_action_pressed("climb_down")

	if up or down:
		_climbing = true

	if _climbing:
		velocity.x = 0.0
		velocity.y = 0.0
		if up:
			velocity.y = -CLIMB_SPEED
		elif down:
			velocity.y = CLIMB_SPEED
		return true

	velocity.x = 0.0
	velocity.y = 0.0
	return true

# -------------------------
# DASH
# -------------------------
func _handle_dash_timers(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	dash_charges = mini(dash_charges, get_max_dash_charges())
	if dash_charges < get_max_dash_charges():
		dash_regen_timer += delta
		if dash_regen_timer >= DASH_COOLDOWN:
			dash_charges += 1
			dash_regen_timer = 0.0

func _try_dash() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0 and dash_charges > 0:
		dash_charges -= 1
		dash_regen_timer = 0.0
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = Vector2(dir, 0).normalized()
		_play_dash_effect()

# -------------------------
# JUMP TIMERS
# -------------------------
func _handle_jump_timers(delta: float) -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = COYOTE_TIME
	elif is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_was_on_floor = is_on_floor()

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

# -------------------------
# BLOCK / PARRY TIMERS
# -------------------------
func _handle_block_timers(delta: float) -> void:
	_is_blocking = Input.is_action_pressed("block")

	if Input.is_action_just_pressed("block"):
		_parry_timer  = PARRY_WINDOW
		_parry_active = true
	elif _parry_active:
		_parry_timer -= delta
		if _parry_timer <= 0.0:
			_parry_active = false

# -------------------------
# GRAVITY
# -------------------------
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# -------------------------
# MANA
# -------------------------
func _regen_mana(delta: float) -> void:
	if hitbox.get_active_effects().has("mana_drain"):
		return
	if Player_Global_Data.p_curr_mana < Player_Global_Data.p_max_mana:
		Player_Global_Data.p_curr_mana = minf(
			Player_Global_Data.p_curr_mana + (mana_regen_rate + hitbox.effects.magnitude("buff_mana_regen")) * delta,
			Player_Global_Data.p_max_mana
		)

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(_event: InputEvent) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
	if Input.is_action_just_pressed("casting_aim_lock"):
		_stop_moving_locked = not _stop_moving_locked
		Player_Global_Data.p_moveable = not _stop_moving_locked
		if stop_label:
			stop_label.text = "STOP MODE"
			stop_label.visible = _stop_moving_locked

	# Aim lock flag updated regardless of p_moveable — aim lock IS the casting stance
	if _in_casting_stance:
		_aim_locked = Input.is_action_pressed("casting_aim_lock")

	# Casting inputs are intentionally allowed even when movement is locked (aim lock mode)
	if combat_mode:
		if Input.is_action_just_pressed("start_incantation"):
			if hitbox.is_silenced():
				spell_label.text = "Silenced!"
				return
			if _in_casting_stance:
				var confirmed := incantations.confirm()
				if confirmed:
					_cast_resolved(confirmed)
				_exit_casting_stance()
			else:
				_enter_casting_stance()

		if _in_casting_stance:
			_process_incantation_inputs()

	if not Player_Global_Data.p_moveable:
		return

	if Input.is_action_just_pressed("dash") \
		and not is_dashing \
		and not hitbox.is_stunned() \
		and dash_charges > 0:
			_try_dash()

	if combat_mode:
		_handle_combat_input()

# -------------------------
# CASTING STANCE
# -------------------------
func _enter_casting_stance() -> void:
	incantations.clear()
	_in_casting_stance = true
	Player_Global_Data.is_casting = true
	spell_string.clear()
	spell_label.text = ""
	_clear_spell_icons()

func _exit_casting_stance() -> void:
	incantations.clear()
	_in_casting_stance = false
	_aim_locked = false
	Player_Global_Data.is_casting = false
	spell_string.clear()
	spell_label.text = ""
	_clear_spell_icons()

# -------------------------
# SPELLS
# -------------------------
func _sync_spells_from_global() -> void:
	spell_inventory = Player_Global_Data.equipped_spells.duplicate()
	incantations.strategy = incantation_strategy
	incantations.rebuild(spell_inventory)

func _has_partial_match(candidate: Array) -> bool:
	return not candidate.is_empty() and incantations.accepts(candidate.back())

func _has_chain_potential(_current_sequence: Array) -> bool:
	return incantations.has_extension()

func _add_sequence(incantation: String) -> void:
	var matched_spell := incantations.push(incantation)
	spell_string = incantations.sequence.duplicate()
	_update_spell_icons()
	if matched_spell:
		_cast_resolved(matched_spell)

func _cast_resolved(spell: SpellData) -> void:
	var accepted: bool
	var aim := castMarker.position.normalized()
	var targets: Array[Node2D] = []
	if LegacySpellAdapter.delivery_for(spell) == SpellData.Delivery.DIRECT_TARGET:
		var targeting_context := SpellCastContext.new(self, spell)
		targeting_context.direction = aim
		var target := SpellDelivery.pick_target(targeting_context)
		if target: targets.append(target)
	if incantation_strategy == IncantationResolver.Strategy.CHAINED:
		accepted = casting.enqueue_cast(spell, castMarker.global_position, aim, targets)
	else:
		accepted = casting.request_cast(spell, castMarker.global_position, aim, targets)
	if accepted:
		spell_label.text = spell.spell_name + " cast!"

func _clear_sequence() -> void:
	incantations.clear()
	casting.cancel()
	spell_string.clear()
	spell_label.text = ""
	_clear_spell_icons()

func _clear_spell_icons() -> void:
	if not spell_icon_box:
		return
	for child in spell_icon_box.get_children():
		child.queue_free()

func _update_spell_icons() -> void:
	if not spell_icon_box:
		return
	_clear_spell_icons()
	for direction in spell_string:
		var key: String = direction.to_lower()
		if key in DIRECTION_ICONS:
			var icon := TextureRect.new()
			icon.texture = load(DIRECTION_ICONS[key])
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(24, 24)
			spell_icon_box.add_child(icon)

func _find_spell_match() -> SpellData:
	for spell in spell_inventory:
		var spell_keys = spell.spell_incantation.filter(func(k): return k != "")
		if spell_keys == spell_string:
			return spell
	return null

# Compatibility entry points delegate to the same service.
func _execute_spell_instantiation(spell: SpellData) -> void:
	_cast_resolved(spell)
func _execute_projectile(spell: SpellData) -> void:
	_cast_resolved(spell)
func _execute_healing(spell: SpellData) -> void:
	_cast_resolved(spell)
func _execute_buff(spell: SpellData) -> void:
	_cast_resolved(spell)
func _execute_decast(spell: SpellData) -> void:
	_cast_resolved(spell)

func _on_cast_failed(message: String) -> void:
	# A failed short prefix must not discard the path to a longer combo.
	_fail_cast(message, incantation_strategy != IncantationResolver.Strategy.CHAINED)

func _fail_cast(message: String, reset_input: bool = true) -> void:
	if reset_input:
		incantations.clear()
		_clear_spell_icons()
		spell_string.clear()
	spell_label.text = message
	get_tree().create_timer(0.5).timeout.connect(_clear_cast_message.bind(message), CONNECT_ONE_SHOT)

func _clear_cast_message(message: String) -> void:
	if _in_casting_stance and spell_label.text == message:
		spell_label.text = ""

# -------------------------
# FLOATING INDICATOR
# -------------------------
func _spawn_indicator(text: String, color: String = "#FFFFFF", duration: float = 0.6) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color.from_string(color, Color.WHITE))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.global_position = global_position + Vector2(-20.0, -80.0)
	lbl.z_index = 10
	get_parent().add_child(lbl)

	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "global_position",
		lbl.global_position + Vector2(0.0, -48.0), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)

func _spawn_particles(scene: PackedScene) -> void:
	if not scene:
		return
	var inst := scene.instantiate() as GPUParticles2D
	if not inst:
		return
	inst.global_position = global_position
	inst.emitting = true
	inst.one_shot = true
	get_parent().add_child(inst)
	get_tree().create_timer(inst.lifetime + 0.5).timeout.connect(inst.queue_free, CONNECT_ONE_SHOT)

# -------------------------
# HITBOX HANDLERS
# -------------------------
func _on_damage_taken(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self):
		return
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_remote_health = maxf(_remote_health - amount, 0)
		if _remote_health <= 0:
			hitbox.died.emit()
		return
	# ---- PARRY: full negation ----
	if _parry_active:
		_parry_active = false
		_spawn_indicator("PARRIED!", "#A78BFA")
		_spawn_particles(parry_particles_scene)
		spell_label.text = "Parried!"
		var label_ref := spell_label
		get_tree().create_timer(0.5).timeout.connect(func():
			if label_ref: label_ref.text = ""
		, CONNECT_ONE_SHOT)
		return

	# ---- BLOCK: negate damage, pay HP + mana cost ----
	if _is_blocking:
		var hp_cost   = Player_Global_Data.p_max_health * BLOCK_HP_COST_FRACTION
		var mana_cost = Player_Global_Data.p_max_mana   * BLOCK_MANA_COST_FRACTION
		Player_Global_Data.p_curr_health = maxf(Player_Global_Data.p_curr_health - hp_cost,   0.0)
		Player_Global_Data.p_curr_mana   = maxf(Player_Global_Data.p_curr_mana   - mana_cost, 0.0)
		_spawn_indicator("BLOCKED!", "#60A5FA")
		_spawn_particles(block_particles_scene)
		spell_label.text = "Blocked!"
		var label_ref := spell_label
		get_tree().create_timer(0.4).timeout.connect(func():
			if label_ref: label_ref.text = ""
		, CONNECT_ONE_SHOT)
		return

	# ---- Normal hit ----
	casting.cancel("Interrupted by damage")
	Player_Global_Data.p_curr_health = maxf(
		Player_Global_Data.p_curr_health - amount, 0.0
	)

func _on_died() -> void:
	casting.cancel("Caster died")
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		hitbox.clear_all_effects()
		return
	Player_Global_Data.p_moveable = false
	hitbox.clear_all_effects()
	_exit_casting_stance()

func _on_mana_drained(amount: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_remote_mana = maxf(_remote_mana - amount, 0)
		return
	if _parry_active or _is_blocking:
		return
	Player_Global_Data.p_curr_mana = maxf(
		Player_Global_Data.p_curr_mana - amount, 0.0
	)

func _on_knocked_back(force: Vector2) -> void:
	if _parry_active or _is_blocking:
		return
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0

func _on_status_applied(effect_name: String) -> void:
	if effect_name in ["stun", "silence"]:
		casting.cancel("Cast interrupted")
	if _parry_active:
		hitbox.remove_effect(effect_name)
		return

	match effect_name:
		"stun":
			_exit_casting_stance()
		"silence":
			_exit_casting_stance()
			spell_label.text = "Silenced!"
		"slow":
			pass
		"dot":
			pass
		"mana_drain":
			pass

func _on_status_expired(effect_name: String) -> void:
	match effect_name:
		"stun":
			Player_Global_Data.p_moveable = true
		"silence":
			spell_label.text = ""
		"slow":
			pass

# -------------------------
# AIM
# -------------------------
func _update_aim_direction() -> void:
	var aim_input = Input.get_vector("move_left", "move_right", "climb_up", "climb_down")
	if aim_input != Vector2.ZERO:
		var target_pos = Vector2.ZERO
		target_pos.x = aim_input.x * 140.0
		target_pos.y = -180.0 if aim_input.y < 0 else (180.0 if aim_input.y > 0 else 0.0)
		if aim_input.y == 0:
			target_pos.y = 0.0
		castMarker.position = target_pos

# -------------------------
# COMBAT MODE
# -------------------------
func _on_combat_mode_changed(is_combat: bool) -> void:
	if not is_inside_tree(): await ready
	var target_zoom = Vector2(0.7, 0.7) if is_combat else Vector2(1.0, 1.0)
	create_tween().tween_property(camera, "zoom", target_zoom, 0.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	camera.position_smoothing_speed = 25.0 if is_combat else 5.0
	if not is_combat:
		_exit_casting_stance()

# -------------------------
# EFFECTS
# -------------------------
func _play_dash_effect() -> void:
	if not dash_particles:
		return
	var mat := dash_particles.process_material as ParticleProcessMaterial
	if not mat:
		return
	dash_particles.global_position = global_position
	mat.direction = Vector3(-dash_direction.x, -dash_direction.y, 0)
	dash_particles.restart()

func can_cast_spell(spell: SpellData) -> bool:
	return is_multiplayer_authority() and Player_Global_Data.has_spell(spell) and Player_Global_Data.is_spell_equipped(spell)

func consume_spell_mana(amount: float) -> bool:
	if not is_finite(amount) or amount < 0:
		return false
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		if _remote_mana < amount:
			return false
		_remote_mana -= amount
		return true
	return Player_Global_Data.consume_mana(amount)

func restore_spell_mana(amount: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_remote_mana = minf(_remote_mana + amount, 400)
	else:
		Player_Global_Data.restore_mana(amount)

func restore_spell_health(amount: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		_remote_health = minf(_remote_health + amount, 100)
	else:
		Player_Global_Data.p_curr_health += int(amount)

func get_max_dash_charges() -> int:
	var h := get_node_or_null("HitboxComponent") as HitboxComponent
	return maxi(0, max_dashes + int(h.effects.magnitude("buff_dash_charges") if h else 0))
