class_name Enemy extends CharacterBody2D
static var _next_spawn_id: int = 0

static func allocate_spawn_id(prefix: String) -> String:
	_next_spawn_id += 1
	return "%s:%d" % [prefix, _next_spawn_id]

signal enemy_died
signal enemy_hurt(amount: float)
signal state_changed(new_state: State)
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEATH, RETURN }
enum AttackType { MELEE, RANGED, BOTH }
@export var enemy_data: EnemyData
@export var legacy_spellcaster: NPCSpellcasterData
@export var spawn_id: String = ""
# Legacy scene properties remain public; stats component owns changes at runtime.
@export var enemy_name: String = "Unknown Enemy"
@export var max_health: float = 100
@export var move_speed: float = 80
@export var chase_speed: float = 140
@export var hurt_duration: float = 0.4
@export var damage_reduction: float = 0
@export var damage_multiplier: float = 1
@export var receives_status_effects: bool = true
@export var spell_mana: float = 400
@onready var hitbox: HitboxComponent = %HitboxComponent
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var hurt_timer: Timer = %HurtTimer
@onready var detection: EnemyDetection = %EnemyDetection
@onready var patrol: EnemyPatrol = %EnemyPatrol
@onready var combat: EnemyCombat = %EnemyCombat
var stats: EnemyStatsComponent
var ai: EnemyAIController
var movement: EnemyMovementComponent
var definition: EnemyData
var current_state: State = State.IDLE
var current_health: float = 0
var _facing_right: bool = true
var _death_remaining: float = 0
func _ready() -> void:
	definition = enemy_data if enemy_data else (EnemyDefinitionAdapter.from_spellcaster(legacy_spellcaster) if legacy_spellcaster else EnemyDefinitionAdapter.from_scene(self))
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Invalid enemy definition: " + str(errors)); queue_free(); return
	enemy_name = definition.enemy_name
	set_meta("enemy_id", definition.enemy_id)
	set_meta("faction_id", definition.faction_id)
	set_meta("spell_team", definition.faction_id)
	if spawn_id.is_empty(): spawn_id = allocate_spawn_id("%s:%s" % [definition.enemy_id, get_path()])
	set_meta("enemy_network_id", spawn_id)
	add_to_group("enemy")
	stats = EnemyStatsComponent.new()
	stats.name = "EnemyStatsComponent"
	add_child(stats)
	stats.configure(definition.stats)
	detection.configure(definition.perception)
	hitbox.hit_received.connect(detection.record_hit)
	hitbox.died.connect(_on_died)
	hitbox.receives_status_effects = receives_status_effects
	combat.configure(definition)
	ai = EnemyAIController.new()
	ai.name = "EnemyAIController"
	add_child(ai)
	ai.configure(definition.ai_profile)
	movement = EnemyMovementComponent.new()
	movement.name = "EnemyMovementComponent"
	add_child(movement)
	patrol.patrol_range = definition.ai_profile.patrol_range
	patrol.wall_jump_velocity = definition.ai_profile.wall_jump_velocity
	var animation := get_node_or_null("EnemyAnimationComponent") as EnemyAnimationComponent
	if animation == null:
		animation = EnemyAnimationComponent.new()
		animation.name = "EnemyAnimationComponent"
		add_child(animation)
	animation.bind_enemy(self)
	if definition.visual_scene:
		var visual := definition.visual_scene.instantiate()
		if visual is Node2D: add_child(visual); sprite.hide()
		else: visual.free()
	var loot := get_node_or_null("EnemyLootComponent") as EnemyLootComponent
	if loot: loot.loot_table = definition.loot.duplicate()
	var observer := get_node_or_null("EnemyQuestObserverComponent") as EnemyQuestObserver
	if observer: observer.enemy_id = definition.quest_enemy_id
	hurt_timer.one_shot = true
	hurt_timer.wait_time = maxf(hurt_duration, 0.05)
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	combat.attack_finished.connect(_on_attack_finished)
	detection.connect_area(%DetectionArea)
	_play_animation("idle")
func _physics_process(delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	if current_state == State.DEATH:
		_death_remaining -= delta
		if _death_remaining <= 0: queue_free()
		return
	stats.tick(delta)
	detection.tick(delta)
	if not hitbox.is_stunned() and current_state != State.HURT: patrol.tick(delta, self)
	combat.tick(delta)
	ai.tick(delta)
	movement.tick(delta)
	_apply_gravity(delta)
	move_and_slide()
func _set_state(value: State) -> void:
	if current_state == State.DEATH or current_state == value: return
	current_state = value
	state_changed.emit(value)
func react_to_damage() -> void:
	combat.cancel("Interrupted by damage")
	ai.interrupt()
	_set_state(State.HURT)
	hurt_timer.start()
func die() -> void:
	if not SpellExecutor.is_authoritative(self) or current_state == State.DEATH: return
	current_state = State.DEATH
	set_meta("combat_dead", true)
	remove_from_group("combat_target")
	velocity = Vector2.ZERO
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision: collision.set_deferred("disabled", true)
	combat.cancel("Caster died")
	ai.interrupt()
	hurt_timer.stop()
	hitbox.clear_all_effects()
	CombatLifecycle.cleanup(self)
	_death_remaining = definition.death_delay
	state_changed.emit(State.DEATH)
	enemy_died.emit()
	if definition.experience_reward > 0: Player_Global_Data.player_exp += definition.experience_reward
	if _death_remaining <= 0: queue_free()
func _exit_tree() -> void:
	CombatLifecycle.cleanup(self)
func _on_died() -> void:
	die()
func _on_damage_taken(amount: float) -> void:
	stats.receive_damage(amount)
func _on_attack_finished() -> void:
	if current_state == State.ATTACK: _set_state(State.CHASE if detection.has_line_of_sight() else State.RETURN)
func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		_set_state(State.CHASE if detection.has_line_of_sight() else State.RETURN)
		ai.interrupt()
func _apply_gravity(delta: float) -> void:
	if not is_on_floor(): velocity += get_gravity() * delta
func _update_facing(direction_x: float) -> void:
	if absf(direction_x) > 0.01:
		_facing_right = direction_x > 0
		sprite.flip_h = not _facing_right
func _play_animation(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name): sprite.play(anim_name)
func get_health_ratio() -> float:
	return current_health / maxf(max_health, 1)
func apply_spell_hit(spell: SpellData, direction: Vector2) -> void:
	hitbox.receive_hit(spell, direction)
func can_cast_spell(spell: SpellData) -> bool:
	for ability in combat.loadout:
		if ability.kind == EnemyAbilityData.Kind.SPELL and ability.spell == spell: return true
	return false
func consume_spell_mana(amount: float) -> bool:
	return stats.consume(amount)
func restore_spell_mana(amount: float) -> void:
	stats.restore(amount)
