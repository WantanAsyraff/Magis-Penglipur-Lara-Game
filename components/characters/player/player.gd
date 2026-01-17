# Player.gd
class_name Player
extends CharacterBody2D

# -------------------------
# CONSTANTS & SCENES
# -------------------------
const PROJECTILE_SCENE = preload("res://components/projectiles/magis-projectile.tscn")

@onready var castMarker: Marker2D = %CastDirectionMarker
@onready var spell_label: Label = %castingText

# -------------------------
# DASH SETTINGS
# -------------------------
var DASH_SPEED := 2500.0
var DASH_TIME := 0.15
var DASH_COOLDOWN := 1.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var is_dashing := false
var dash_cooldown_timer := 0.0

# -------------------------
# MOVEMENT
# -------------------------
var SPEED := Player_Global_Data.p_speed
var JUMP_VELOCITY := Player_Global_Data.p_jump_height
var current_mana := Player_Global_Data.p_curr_mana

# -------------------------
# SPELLCASTING
# -------------------------
var is_casting := false
var spell_inventory: Array[SpellData] = []
var spell_string: Array[String] = []

# -------------------------
# UI / SELECTION
# -------------------------
var current_spell_index := 0

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	add_to_group("player")

# -------------------------
# PHYSICS
# -------------------------
func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
	else:
		if dash_cooldown_timer > 0:
			dash_cooldown_timer -= delta

		if not is_on_floor():
			velocity += get_gravity() * delta

		var dir := Input.get_axis("ui_left", "ui_right")
		if dir != 0 and not is_casting:
			velocity.x = dir * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

	move_and_slide()

# -------------------------
# INPUT
# -------------------------
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("start_incantation"):
		is_casting = !is_casting
		spell_string.clear()
		spell_label.text = ""

	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		var dir := Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		if dir != Vector2.ZERO:
			_start_dash(dir.normalized())

	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") \
	or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		_update_aim_direction()

	if is_casting:
		if Input.is_action_just_pressed("incantation_up"):
			_add_sequence("up")
		elif Input.is_action_just_pressed("incantation_down"):
			_add_sequence("down")
		elif Input.is_action_just_pressed("incantation_left"):
			_add_sequence("left")
		elif Input.is_action_just_pressed("incantation_right"):
			_add_sequence("right")

# -------------------------
# DASH
# -------------------------
func _start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_timer = DASH_TIME
	dash_direction = dir

# -------------------------
# SPELL SEQUENCING
# -------------------------
func _add_sequence(incantation: String) -> void:
	spell_string.append(incantation)
	spell_label.text = " → ".join(spell_string)

	if spell_string.size() >= 4:
		_try_cast_spell()

func _try_cast_spell() -> void:
	var matched_spell: SpellData = null

	for spell in spell_inventory:
		if spell.spell_incantation == spell_string:
			matched_spell = spell
			break

	if matched_spell == null:
		_fail_cast("Invalid sequence!")
		return

	if Player_Global_Data.p_curr_mana < matched_spell.upfront_cost:
		_fail_cast("Not enough mana!")
		return

	Player_Global_Data.p_curr_mana -= matched_spell.upfront_cost
	Player_Global_Data.mana_changed.emit(Player_Global_Data.p_curr_mana)

	_cast_spell(matched_spell)
	spell_label.text = matched_spell.spell_name + " cast!"

	_reset_casting()

func _fail_cast(message: String):
	spell_label.text = message
	_reset_casting()

func _reset_casting():
	await get_tree().create_timer(0.5).timeout
	spell_string.clear()
	spell_label.text = ""
	is_casting = false

# -------------------------
# SPELL EXECUTION
# -------------------------
func _cast_spell(spell: SpellData) -> void:
	match spell.spell_type:
		SpellData.SpellType.AOE:
			_cast_aoe_spell(spell)
		_:
			_cast_projectile_spell(spell)

func _cast_projectile_spell(spell: SpellData):
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.spell_data = spell
	projectile.position = castMarker.global_position
	projectile.direction = _get_cast_direction()
	get_parent().add_child(projectile)

func _cast_aoe_spell(spell: SpellData):
	var aoe = PROJECTILE_SCENE.instantiate()
	aoe.spell_data = spell
	aoe.position = castMarker.global_position
	get_parent().add_child(aoe)

func _get_cast_direction() -> Vector2:
	return castMarker.position.normalized()

# -------------------------
# AIMING
# -------------------------
func _update_aim_direction():
	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left"):
		_set_cast_marker(Vector2(-178, -183))
	elif Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right"):
		_set_cast_marker(Vector2(178, -183))
	elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left"):
		_set_cast_marker(Vector2(-178, 183))
	elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right"):
		_set_cast_marker(Vector2(178, 183))
	elif Input.is_action_pressed("ui_up"):
		_set_cast_marker(Vector2(0, -237))
	elif Input.is_action_pressed("ui_down"):
		_set_cast_marker(Vector2(0, 177))
	elif Input.is_action_pressed("ui_left"):
		_set_cast_marker(Vector2(-142, -57))
	elif Input.is_action_pressed("ui_right"):
		_set_cast_marker(Vector2(142, -57))

func _set_cast_marker(pos: Vector2):
	castMarker.position = pos

# -------------------------
# SPELL INVENTORY API
# -------------------------
func add_spell_to_inventory(spell: SpellData):
	if spell_inventory.has(spell):
		return

	if spell_inventory.size() >= 8:
		print("Spell inventory full!")
		return

	spell_inventory.append(spell)
	print("Learned spell:", spell.spell_name)

func add_spells(spells: Array[SpellData]):
	for spell in spells:
		add_spell_to_inventory(spell)
