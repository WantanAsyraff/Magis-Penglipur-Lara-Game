class_name TrainingDummy
extends CharacterBody2D

@export var max_hp: float = 100.0
@export var flash_color: Color = Color(1, 0.2, 0.2)
@export var flash_duration: float = 0.1

var hitbox: HitboxComponent
var mana: float = 100.0
var current_hp: float

const DAMAGE_INDICATOR = preload("res://components/damage-indicator/damage-indicator.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = get_node_or_null("Label") as Label

func _ready() -> void:
	current_hp = max_hp
	collision_layer = 2
	collision_mask = 16
	set_meta("faction_id", &"enemy")
	set_meta("spell_team", &"enemy")
	set_meta("structural", true)
	set_meta("magnetic", true)
	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	add_child(hitbox)
	hitbox.has_mana = true
	hitbox.damage_taken.connect(take_damage)
	hitbox.healed.connect(func(amount): current_hp = minf(max_hp,current_hp+amount); _update_hp_label())
	hitbox.mana_drained.connect(func(amount): mana = maxf(0,mana-amount))
	PlayerEnemyCollision.configure(self)
	_update_hp_label()

func _physics_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x,0,1200*delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp -= amount
	_spawn_indicator(amount)
	_flash()
	_update_hp_label()
	if current_hp <= 0:
		_die()

func _spawn_indicator(amount: float) -> void:
	var indicator = DAMAGE_INDICATOR.instantiate()
	indicator.text = str(snappedf(amount, 0.1))
	indicator.position = global_position + Vector2(randf_range(-10, 10), -40)
	get_parent().add_child(indicator)

func _flash() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", flash_color, flash_duration)
	tween.tween_property(sprite, "modulate", Color.WHITE, flash_duration)

func _update_hp_label() -> void:
	if hp_label:
		hp_label.text = "%d / %d" % [current_hp, max_hp]

func _die() -> void:
	current_hp = max_hp
	_update_hp_label()
