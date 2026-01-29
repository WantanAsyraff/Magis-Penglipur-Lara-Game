class_name Player
extends CharacterBody2D

const PROJECTILE_SCENE := preload("res://components/projectiles/magis-projectile.tscn")

@onready var cast_marker: Marker2D = %CastDirectionMarker
@onready var spell_label: Label = %castingText
@onready var camera: Camera2D = %Camera2D

# ------------------------------------------------------------
# Per-player runtime state (Global = template only)
# ------------------------------------------------------------

# Combat mode (per-player)
var _combat_mode: bool = false
@export var combat_mode: bool:
	set(value):
		if _combat_mode == value:
			return
		_combat_mode = value
		_on_combat_mode_changed(value)
	get:
		return _combat_mode

# Movement (copied from template once)
var SPEED: float = 900.0
var JUMP_VELOCITY: float = -1600.0

# Player runtime flags (per-player)
var moveable: bool = true

# Mana (per-player)
var max_mana: int = 250
var curr_mana: int = 250

# Dash
var DASH_SPEED := 2500.0
var DASH_TIME := 0.15
var DASH_COOLDOWN := 1.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var is_dashing := false
var dash_cooldown_timer := 0.0

# Spells (per-player)
var is_casting := false
var spell_inventory: Array[SpellData] = []
var spell_string: Array[String] = []


func _ready() -> void:
	add_to_group("player")

	# --------------------------------------------------------
	# Copy template -> per-player (do this once on spawn)
	# --------------------------------------------------------
	SPEED = Player_Global_Data.p_speed
	JUMP_VELOCITY = Player_Global_Data.p_jump_height

	moveable = Player_Global_Data.p_moveable

	max_mana = Player_Global_Data.p_max_mana
	curr_mana = Player_Global_Data.p_curr_mana

	spell_inventory = Player_Global_Data.learned_spells.duplicate(true)

	# Initialize combat mode from template
	combat_mode = Player_Global_Data.combat_mode


func _physics_process(delta: float) -> void:
	# Only authority simulates inputs/logic.
	# Non-authority will just move with whatever state you later replicate.
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		move_and_slide()
		return

	_handle_dash_timers(delta)
	_apply_gravity(delta)

	# If not moveable, slow to stop and exit
	if not moveable:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		move_and_slide()
		return

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		_handle_movement()

	move_and_slide()


func _handle_movement() -> void:
	# NOTE: keep your old actions for now; switch away from ui_* later
	var dir := Input.get_axis("ui_left", "ui_right")

	if dir != 0.0 and not is_casting:
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _handle_dash_timers(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
	elif dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _try_dash() -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = dir.normalized()


func _unhandled_input(_event: InputEvent) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return

	if not moveable:
		return

	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0.0:
		_try_dash()

	if Input.is_action_just_pressed("start_incantation"):
		is_casting = !is_casting
		spell_string.clear()
		spell_label.text = ""

	# Only update aim if there is aim input
	_update_aim_direction()

	if is_casting:
		_process_incantation_inputs()


func _process_incantation_inputs() -> void:
	if Input.is_action_just_pressed("incantation_up"):
		_add_sequence("up")
	elif Input.is_action_just_pressed("incantation_down"):
		_add_sequence("down")
	elif Input.is_action_just_pressed("incantation_left"):
		_add_sequence("left")
	elif Input.is_action_just_pressed("incantation_right"):
		_add_sequence("right")


func _add_sequence(incantation: String) -> void:
	spell_string.append(incantation)
	spell_label.text = " → ".join(spell_string)

	if spell_string.size() >= 4:
		_try_cast_spell()


func _try_cast_spell() -> void:
	var matched_spell := _find_spell_match()
	if matched_spell == null:
		_fail_cast("Invalid sequence!")
		return

	if curr_mana < matched_spell.upfront_cost:
		_fail_cast("Not enough mana!")
		return

	curr_mana -= matched_spell.upfront_cost
	_execute_spell_instantiation(matched_spell)

	spell_label.text = matched_spell.spell_name + " cast!"
	_reset_casting_with_delay()


func _find_spell_match() -> SpellData:
	for spell in spell_inventory:
		if spell.spell_incantation == spell_string:
			return spell
	return null


func _execute_spell_instantiation(spell: SpellData) -> void:
	var inst := PROJECTILE_SCENE.instantiate()
	inst.spell_data = spell
	inst.position = cast_marker.global_position

	if spell.spell_type != SpellData.SpellType.AOE:
		inst.direction = cast_marker.position.normalized()

	get_parent().add_child(inst)


func _fail_cast(message: String) -> void:
	spell_label.text = message
	_reset_casting_with_delay()


func _reset_casting_with_delay() -> void:
	await get_tree().create_timer(0.5).timeout
	_cancel_casting()


func _cancel_casting() -> void:
	is_casting = false
	spell_string.clear()
	spell_label.text = ""


func _update_aim_direction() -> void:
	var aim_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if aim_input == Vector2.ZERO:
		return

	# Keep your existing feel (but avoid weird y rules)
	var target_pos := Vector2(aim_input.x * 142.0, aim_input.y * 177.0)

	# Up uses a bigger negative reach like your original
	if aim_input.y < 0.0:
		target_pos.y = -237.0
	elif aim_input.y == 0.0:
		target_pos.y = -57.0

	cast_marker.position = target_pos


func _on_combat_mode_changed(is_combat: bool) -> void:
	if not is_inside_tree():
		await ready

	var target_zoom := Vector2(0.7, 0.7) if is_combat else Vector2(1.0, 1.0)
	create_tween() \
		.tween_property(camera, "zoom", target_zoom, 0.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	if not is_combat:
		_cancel_casting()
