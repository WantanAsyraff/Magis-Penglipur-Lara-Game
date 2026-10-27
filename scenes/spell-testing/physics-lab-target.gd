class_name PhysicsLabTarget extends CharacterBody2D
var health: float = 200
var moving: bool = false
var title: String = "Dummy"
var home: Vector2
var elapsed: float = 0
var hitbox: HitboxComponent
var label: Label
func _ready() -> void:
	home = position
	collision_layer = 2
	collision_mask = 16
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	add_child(shape)
	hitbox = HitboxComponent.new()
	hitbox.name = "HitboxComponent"
	hitbox.has_mana = true
	add_child(hitbox)
	hitbox.damage_taken.connect(func(amount): health -= amount)
	hitbox.healed.connect(func(amount): health += amount)
	label = Label.new()
	label.position = Vector2(-65, -80)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
func _physics_process(delta: float) -> void:
	elapsed += delta
	velocity.y += 980 * delta
	velocity.x = sin(elapsed * 1.5) * 65 * (1 - hitbox.get_slow_factor()) if moving and not hitbox.is_stunned() else move_toward(velocity.x, 0, 200 * delta)
	move_and_slide()
	if health <= 0: reset_target()
	label.text = "%s\nHP %.0f | %s" % [title, health, ", ".join(hitbox.get_active_effects().keys())]
	queue_redraw()
func reset_target() -> void:
	health = 200
	position = home
	velocity = Vector2.ZERO
	hitbox.clear_all_effects()
func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color(0.9, .5, .3) if has_meta("structural") else Color(.4, .8, .9))
	draw_line(Vector2(-14, -25), Vector2(-14 + 28 * clampf(health / 200, 0, 1), -25), Color.GREEN, 3)
