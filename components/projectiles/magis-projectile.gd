class_name MagicProjectile extends Area2D

var spell_data: SpellData
var direction: Vector2
var lifetime: float = 5.0

var particle_instance: GPUParticles2D  # Reference to spawned particles

func _ready():
	if spell_data:
		# Apply visuals
		$Sprite2D.texture = spell_data.projectile_texture
		$Sprite2D.scale = Vector2.ONE * spell_data.projectile_size
		
		# Spawn trail particles
		if spell_data.projectile_particles:
			particle_instance = spell_data.projectile_particles.instantiate()
			add_child(particle_instance)
			particle_instance.emitting = true
	
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * spell_data.projectile_speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(spell_data.projectile_damage)
		
	if spell_data.stunnable and body.has_method("apply_stun"):
		body.apply_stun(spell_data.stun_dur)
	
	# Spawn impact particles
	if spell_data.impact_particles:
		var impact = spell_data.impact_particles.instantiate()
		get_parent().add_child(impact)  # Add to world, not projectile
		impact.global_position = global_position
		impact.emitting = true
		
		# Auto-cleanup after particles finish
		impact.finished.connect(impact.queue_free)
	
	if not spell_data.piercing:
		queue_free()
