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
		if Player_Global_Data.combat_mode != value:
			Player_Global_Data.combat_mode = value
		_on_combat_mode_changed(value)

@onready var castMarker: Marker2D = %CastDirectionMarker
@onready var spell_label: Label = %castingText
@onready var spell_icon_box: HBoxContainer = %SpellIconBox
@onready var camera: Camera2D = %Camera2D
@onready var dash_particles: GPUParticles2D = %DashParticles
@onready var hitbox: HitboxComponent = $HitboxComponent

# -------------------------
# VARIABLES
# -------------------------
var SPEED := Player_Global_Data.p_speed
var JUMP_VELOCITY := Player_Global_Data.p_jump_height

# Dash — charge based
var DASH_SPEED := 3200.0
var DASH_TIME := 0.12
var DASH_COOLDOWN := 1.4
var max_dashes = Player_Global_Data.MAX_DASH_CHARGES

var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var is_dashing := false
var dash_charges: int = Player_Global_Data.MAX_DASH_CHARGES:
	set(value):
		dash_charges = clampi(value, 0, max_dashes)
		Player_Global_Data.current_dash_charges = dash_charges
var dash_regen_timer := 0.0

# Spells
var spell_inventory: Array[SpellData] = []
var spell_string: Array[String] = []

# Casting stance — stays open until toggled off with "o"
var _in_casting_stance: bool = false

# Aim lock — true while shift is held during casting stance
var _aim_locked: bool = false

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
	Player_Global_Data.current_dash_charges = dash_charges

	# Hitbox setup
	hitbox.receives_status_effects = true
	hitbox.has_mana = true
	hitbox.receives_knockback = true
	hitbox.damage_taken.connect(_on_damage_taken)
	hitbox.died.connect(_on_died)
	hitbox.status_applied.connect(_on_status_applied)
	hitbox.status_expired.connect(_on_status_expired)
	hitbox.mana_drained.connect(_on_mana_drained)
	hitbox.knocked_back.connect(_on_knocked_back)

# -------------------------
# LOGIC: PHYSICS & MOVEMENT
# -------------------------
func _physics_process(delta: float) -> void:
	_handle_dash_timers(delta)
	_apply_gravity(delta)
	_update_aim_direction()
	_regen_mana(delta)

	# Stun halts all movement immediately
	if hitbox.is_stunned():
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if not Player_Global_Data.p_moveable:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		_handle_movement()

	move_and_slide()

func _handle_movement() -> void:
	if _aim_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		return

	var current_speed := SPEED * (1.0 - hitbox.get_slow_factor())

	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0:
		velocity.x = dir * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# -------------------------
# DASH
# -------------------------
func _handle_dash_timers(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	if dash_charges < max_dashes:
		dash_regen_timer += delta
		if dash_regen_timer >= DASH_COOLDOWN:
			dash_charges += 1
			dash_regen_timer = 0.0

func _try_dash() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0 and dash_charges > 0:
		dash_charges -= 1
		dash_regen_timer = 0.0
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = Vector2(dir, 0).normalized()
		_play_dash_effect()

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
			Player_Global_Data.p_curr_mana + mana_regen_rate * delta,
			Player_Global_Data.p_max_mana
		)

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(_event: InputEvent) -> void:
	if not Player_Global_Data.p_moveable:
		return

	if _in_casting_stance:
		_aim_locked = Input.is_action_pressed("casting_aim_lock")

	if Input.is_action_just_pressed("dash") \
		and not is_dashing \
		and not hitbox.is_stunned() \
		and dash_charges > 0:
			_try_dash()

	if combat_mode:
		_handle_combat_input()

	if Input.is_action_just_pressed("start_incantation") and combat_mode:
		if hitbox.is_silenced():
			spell_label.text = "Silenced!"
			return
		if _in_casting_stance:
			_exit_casting_stance()
		else:
			_enter_casting_stance()

	if _in_casting_stance and combat_mode:
		_process_incantation_inputs()

func _handle_combat_input() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	move_and_slide()

func _process_incantation_inputs() -> void:
	if hitbox.is_stunned() or hitbox.is_silenced():
		return
	if Input.is_action_just_pressed("incantation_up"):    _add_sequence("up")
	elif Input.is_action_just_pressed("incantation_down"):  _add_sequence("down")
	elif Input.is_action_just_pressed("incantation_left"):  _add_sequence("left")
	elif Input.is_action_just_pressed("incantation_right"): _add_sequence("right")

# -------------------------
# CASTING STANCE
# -------------------------
func _enter_casting_stance() -> void:
	_in_casting_stance = true
	Player_Global_Data.is_casting = true
	spell_string.clear()
	spell_label.text = ""
	_clear_spell_icons()

func _exit_casting_stance() -> void:
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

func _add_sequence(incantation: String) -> void:
	spell_string.append(incantation)
	_update_spell_icons()

	var matched_spell = _find_spell_match()
	if matched_spell:
		if Player_Global_Data.p_curr_mana < matched_spell.upfront_cost:
			_fail_cast("Not enough mana!")
		else:
			Player_Global_Data.p_curr_mana -= matched_spell.upfront_cost
			_execute_spell_instantiation(matched_spell)
			_clear_spell_icons()
			spell_label.text = matched_spell.spell_name + " cast!"
			await get_tree().create_timer(0.5).timeout
			spell_string.clear()
			if _in_casting_stance:
				spell_label.text = ""

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

func _execute_spell_instantiation(spell: SpellData) -> void:
	var scene_to_use = spell.spell_scene if spell.spell_scene else PROJECTILE_SCENE
	var base_dir = castMarker.position.normalized()
	var count = max(1, spell.projectile_count)

	for i in count:
		var inst = scene_to_use.instantiate()
		inst.spell_data = spell
		inst.position = castMarker.global_position

		if spell.is_self_cast:
			inst.position = global_position
		elif spell.spell_type != SpellData.SpellType.AOE:
			if count == 1:
				inst.direction = base_dir
			else:
				var step = (spell.projectile_spread / (count - 1)) if count > 1 else 0.0
				var angle_offset = deg_to_rad(-spell.projectile_spread / 2.0 + step * i)
				inst.direction = base_dir.rotated(angle_offset)

		get_parent().add_child(inst)

func _fail_cast(message: String) -> void:
	_clear_spell_icons()
	spell_label.text = message
	await get_tree().create_timer(0.5).timeout
	spell_string.clear()
	if _in_casting_stance:
		spell_label.text = ""

# -------------------------
# HITBOX HANDLERS
# -------------------------
func _on_damage_taken(amount: float) -> void:
	Player_Global_Data.p_curr_health = maxf(
		Player_Global_Data.p_curr_health - amount, 0.0
	)

func _on_died() -> void:
	Player_Global_Data.p_moveable = false
	hitbox.clear_all_effects()
	_exit_casting_stance()

func _on_mana_drained(amount: float) -> void:
	Player_Global_Data.p_curr_mana = maxf(
		Player_Global_Data.p_curr_mana - amount, 0.0
	)

func _on_knocked_back(force: Vector2) -> void:
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0

func _on_status_applied(effect_name: String) -> void:
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
	var aim_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
