class_name Player
extends CharacterBody2D

# -------------------------
# CONSTANTS & SCENES
# -------------------------
const PROJECTILE_SCENE = preload("res://components/projectiles/magis-projectile.tscn")

@export var combat_mode: bool = false:
	set(value):
		combat_mode = value
		if Player_Global_Data.combat_mode != value:
			Player_Global_Data.combat_mode = value
		_on_combat_mode_changed(value)

@onready var castMarker: Marker2D = %CastDirectionMarker
@onready var spell_label: Label = %castingText
@onready var camera: Camera2D = %Camera2D

# -------------------------
# VARIABLES
# -------------------------
var SPEED := Player_Global_Data.p_speed
var JUMP_VELOCITY := Player_Global_Data.p_jump_height

# Dash
var DASH_SPEED := 2500.0
var DASH_TIME := 0.15
var DASH_COOLDOWN := 1.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var is_dashing := false
var dash_cooldown_timer := 0.0

# Spells
var is_casting := false
var spell_inventory: Array[SpellData] = []
var spell_string: Array[String] = []

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	add_to_group("player")
	_sync_spells_from_global()
	Player_Global_Data.combat_mode_changed.connect(func(new_val): combat_mode = new_val)
	
	if Player_Global_Data.has_signal("spells_updated"):
		Player_Global_Data.spells_updated.connect(_sync_spells_from_global)
	
	combat_mode = Player_Global_Data.combat_mode

# -------------------------
# LOGIC: PHYSICS & MOVEMENT
# -------------------------
func _physics_process(delta: float) -> void:
	_handle_dash_timers(delta)
	
	# APPLY GRAVITY (Always apply so player sits on floor during dialogue)
	_apply_gravity(delta)

	# CHECK GLOBAL MOVEABLE STATE
	if not Player_Global_Data.p_moveable:
		# Slow down to a stop if we were moving
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return # STOP HERE: Do not process inputs or dashing

	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		_handle_movement()

	move_and_slide()

func _handle_movement() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	
	if dir != 0 and not is_casting:
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_dash_timers(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
	elif dash_cooldown_timer > 0:
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

func _handle_combat_input() -> void:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		move_and_slide()

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(_event: InputEvent) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
		
	# Stop all inputs (Dash/Combat) if not moveable
	if not Player_Global_Data.p_moveable:
		return

	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		_try_dash()

	if combat_mode:
		_handle_combat_input()
	if Input.is_action_just_pressed("start_incantation"):
		is_casting = !is_casting
		spell_string.clear()
		spell_label.text = ""
	_update_aim_direction()
	if is_casting:
		_process_incantation_inputs()

func _process_incantation_inputs() -> void:
	if Input.is_action_just_pressed("incantation_up"): _add_sequence("up")
	elif Input.is_action_just_pressed("incantation_down"): _add_sequence("down")
	elif Input.is_action_just_pressed("incantation_left"): _add_sequence("left")
	elif Input.is_action_just_pressed("incantation_right"): _add_sequence("right")

func _sync_spells_from_global() -> void:
	spell_inventory = Player_Global_Data.learned_spells.duplicate()

func _add_sequence(incantation: String) -> void:
	spell_string.append(incantation)
	spell_label.text = " → ".join(spell_string)
	if spell_string.size() >= 4:
		_try_cast_spell()

func _try_cast_spell() -> void:
	var matched_spell = _find_spell_match()
	if not matched_spell:
		_fail_cast("Invalid sequence!")
		return
	if Player_Global_Data.p_curr_mana < matched_spell.upfront_cost:
		_fail_cast("Not enough mana!")
		return
	Player_Global_Data.p_curr_mana -= matched_spell.upfront_cost
	_execute_spell_instantiation(matched_spell)
	spell_label.text = matched_spell.spell_name + " cast!"
	_reset_casting_with_delay()

func _find_spell_match() -> SpellData:
	for spell in spell_inventory:
		if spell.spell_incantation == spell_string:
			return spell
	return null

func _execute_spell_instantiation(spell: SpellData) -> void:
	var inst = PROJECTILE_SCENE.instantiate()
	inst.spell_data = spell
	inst.position = castMarker.global_position
	if spell.spell_type != SpellData.SpellType.AOE:
		inst.direction = castMarker.position.normalized()
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
	var aim_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if aim_input != Vector2.ZERO:
		var target_pos = Vector2.ZERO
		target_pos.x = aim_input.x * 142
		target_pos.y = -237 if aim_input.y < 0 else (177 if aim_input.y > 0 else 0)
		if aim_input.y == 0:
			target_pos.y = -57
		castMarker.position = target_pos

func _on_combat_mode_changed(is_combat: bool) -> void:
	if not is_inside_tree(): await ready
	var target_zoom = Vector2(0.7, 0.7) if is_combat else Vector2(1.0, 1.0)
	create_tween().tween_property(camera, "zoom", target_zoom, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not is_combat:
		_cancel_casting()
