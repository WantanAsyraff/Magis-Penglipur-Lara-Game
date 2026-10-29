class_name EnvironmentCrate extends RigidBody2D
signal broken
@export var max_health: float = 60.0
@export var persistent: bool = false
@export var visual_data: EnvironmentVisualData
var health := 0.0
var hitbox: HitboxComponent
var visual: InteractionVisual
var _origin := Vector2.ZERO
func _ready() -> void:
	_origin = position
	collision_layer = 16; collision_mask = 17
	set_meta("faction_id",&"neutral"); set_meta("spell_team",&"neutral")
	set_meta("structural",true); set_meta("magnetic",true)
	var collision := CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = Vector2(64,64); collision.shape = rect; add_child(collision)
	hitbox = HitboxComponent.new(); hitbox.name = "HitboxComponent"; add_child(hitbox); remove_from_group("combat_target")
	hitbox.damage_taken.connect(_damage)
	var target := EnvironmentalTarget.new(); target.name = "EnvironmentalTarget"; add_child(target)
	var receiver := InteractionReceiver.new(); receiver.name = "InteractionReceiver"; add_child(receiver)
	visual = InteractionVisual.new(); add_child(visual)
	var cfg := EnvironmentDeviceData.new(); cfg.kind = EnvironmentDeviceData.Kind.BREAKABLE; cfg.size = Vector2(64,64); cfg.visual = visual_data; visual.configure(cfg)
	reset()
	if persistent and WorldPersistence.has_state(self,"broken"): _damage(max_health)
func _damage(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self) or get_meta("combat_dead",false): return
	health = maxf(0,health-amount)
	visual.present(true,&"damaged")
	if health <= 0:
		set_meta("combat_dead",true); set_deferred("collision_layer",0); set_deferred("collision_mask",0); set_deferred("freeze",true)
		visual.present(false,&"broken")
		if persistent: WorldPersistence.mark(self,"broken")
		broken.emit()
func reset() -> void:
	position = _origin; linear_velocity = Vector2.ZERO; angular_velocity = 0; rotation = 0
	health = max_health; set_meta("combat_dead",false); collision_layer = 16; collision_mask = 17; freeze = false
	if visual: visual.present(false)
	reset_physics_interpolation()
