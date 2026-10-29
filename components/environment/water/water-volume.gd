class_name WaterVolume2D extends Area2D
signal player_entered(player: Player)
signal player_exited(player: Player)
@export var region: Vector2 = Vector2(500,300)
@export_range(0,1) var fill: float = 1.0
@export var buoyancy: float = 2.0
@export var drag: float = 3.0
@export var current: Vector2 = Vector2.ZERO
@export var player_swimming: bool = true
@export var swim_speed: float = 320.0
@export var splash: PackedScene
@export var surface_texture: Texture2D
var _shape: CollisionShape2D
var _players: Array[Player] = []
func _ready() -> void:
	if not region.is_finite() or region.x <= 0 or region.y <= 0 or not current.is_finite() or not is_finite(buoyancy) or not is_finite(drag) or buoyancy < 0 or drag < 0:
		push_error("Water requires a positive region and finite nonnegative forces"); set_physics_process(false); return
	fill = clampf(fill,0,1) if is_finite(fill) else 0
	collision_layer = 0; collision_mask = 17
	_shape = CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = region; _shape.shape = rect; add_child(_shape)
	body_entered.connect(_entered); body_exited.connect(_exited)
	add_to_group("water_volumes")
func set_fill(value: float) -> void:
	if not is_finite(value): return
	fill = clampf(value,0,1); queue_redraw()
func surface_y() -> float:
	return global_position.y+region.y/2-region.y*fill
func contains_body(body: Node2D) -> bool:
	var bounds := SpellDelivery.target_bounds(body)
	return fill > 0 and bounds.end.y > surface_y() and bounds.position.y < global_position.y+region.y/2 and absf(body.global_position.x-global_position.x) < region.x/2
func _entered(body: Node2D) -> void:
	if body is Player:
		if not _players.has(body): _players.append(body)
		if not body.water_movement.volumes.has(self): body.water_movement.volumes.append(self)
		player_entered.emit(body)
		if splash:
			var effect := splash.instantiate(); add_child(effect)
			if effect is GPUParticles2D or effect is CPUParticles2D: effect.one_shot = true; effect.emitting = true; effect.finished.connect(effect.queue_free)
func _exited(body: Node2D) -> void:
	if body is Player:
		_players.erase(body)
		if is_instance_valid(body.water_movement): body.water_movement.volumes.erase(self)
		player_exited.emit(body)
func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player) and is_instance_valid(player.water_movement): player.water_movement.volumes.erase(self)
func _physics_process(_delta: float) -> void:
	if not SpellExecutor.is_authoritative(self): return
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity",980)
	for body in get_overlapping_bodies():
		if not body is RigidBody2D or not contains_body(body): continue
		var bounds := SpellDelivery.target_bounds(body)
		var fraction := clampf((bounds.end.y-surface_y())/maxf(1,bounds.size.y),0,1)
		body.apply_central_force(Vector2(0,-gravity*body.mass*buoyancy*fraction)-body.linear_velocity*drag*body.mass*fraction+current*body.mass*fraction)
	queue_redraw()
func _draw() -> void:
	if fill <= 0: return
	var top := region.y/2-region.y*fill
	var rect := Rect2(Vector2(-region.x/2,top),Vector2(region.x,region.y*fill))
	draw_rect(rect,Color(.14,.45,.7,.38))
	if surface_texture: draw_texture_rect(surface_texture,Rect2(rect.position,Vector2(region.x,12)),true)
	else: draw_line(rect.position,rect.position+Vector2(region.x,0),Color(.4,.8,1,.9),3)
