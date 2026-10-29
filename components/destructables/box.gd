extends RigidBody2D

@export var max_health := 10
var health: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if WorldPersistence.has_state(self,"broken"):
		queue_free()
		return
	health = max_health
	particles.emitting = false
	particles.one_shot = true
	set_meta("faction_id", &"neutral")
	set_meta("spell_team", &"neutral")
	set_meta("structural", true)
	set_meta("magnetic", true)
	if get_node_or_null("HitboxComponent") == null:
		var hitbox := HitboxComponent.new()
		hitbox.name = "HitboxComponent"
		add_child(hitbox)
		remove_from_group("combat_target")
		hitbox.has_mana = false
		hitbox.damage_taken.connect(func(amount): take_damage(ceili(amount)))
		var target := EnvironmentalTarget.new()
		target.name = "EnvironmentalTarget"
		add_child(target)

# This is what your MagicProjectile calls
func take_damage(amount: int) -> void:
	if not SpellExecutor.is_authoritative(self) or get_meta("combat_dead", false): return
	health -= amount

	if health <= 0:
		break_object()

func break_object() -> void:
	set_meta("combat_dead", true)
	WorldPersistence.mark(self,"broken")
	# stop interacting with the world
	collision.set_deferred("disabled",true)
	sprite.visible = false

	# play break effect
	particles.emitting = true

	# wait for particles, then remove object
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
