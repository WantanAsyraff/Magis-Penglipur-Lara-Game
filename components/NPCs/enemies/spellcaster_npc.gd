class_name SpellCasterNPC
extends CharacterBody2D

# ─────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────
@export var data: NPCSpellcasterData

# ─────────────────────────────────────────
# STATE
# ─────────────────────────────────────────
var current_hp: float
var is_alive: bool = true
var player: CharacterBody2D

# ─────────────────────────────────────────
# CHILD COMPONENTS
# ─────────────────────────────────────────
@onready var brain: NpcCasterBrain = $NpcCasterBrain
@onready var spell_handler: NpcSpellHandler = $NpcSpellHandler

# ─────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	if not data:
		push_error("SpellCasterNPC: No NpcCasterData assigned!")
		return
	current_hp = data.max_hp

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# ─────────────────────────────────────────
# PLAYER REFERENCE  (lazy — player may
# spawn after NPC)
# ─────────────────────────────────────────
func _get_player() -> CharacterBody2D:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	return player

# ─────────────────────────────────────────
# MOVEMENT  (called by brain)
# ─────────────────────────────────────────
func move_toward_player(_delta: float) -> void:
	var p = _get_player()
	if not p:
		return
	var direction = (p.global_position - global_position).normalized()
	velocity.x = direction.x * data.move_speed

func move_away_from_player(_delta: float) -> void:
	var p = _get_player()
	if not p:
		return
	var direction = (global_position - p.global_position).normalized()
	velocity.x = direction.x * data.move_speed

func stop_moving() -> void:
	velocity.x = move_toward(velocity.x, 0, data.move_speed)

# ─────────────────────────────────────────
# COMBAT
# ─────────────────────────────────────────
func take_damage(amount: float) -> void:
	if not is_alive:
		return
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	is_alive = false

func get_distance_to_player() -> float:
	var p = _get_player()
	if not p:
		return INF
	return global_position.distance_to(p.global_position)
