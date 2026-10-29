class_name EnvironmentMovingPlatform extends AnimatableBody2D
@export var data: MovingPlatformData
@export var waypoints: PackedVector2Array = PackedVector2Array([Vector2.ZERO,Vector2(0,-260)])
@export var waypoint_nodes: Array[NodePath] = []
@export var links: Array[EnvironmentLink] = []
@export var input_sources: Array[NodePath] = []
var actuator: InteractionActuator
var visual: InteractionVisual
var _origin := Vector2.ZERO
var _points: PackedVector2Array
var _next := 1
var _direction := 1
var _wait := 0.0
func _ready() -> void:
	if data == null: data = MovingPlatformData.new()
	if not data.validate().is_empty(): push_error(str(data.validate())); set_physics_process(false); return
	collision_layer = 16; collision_mask = 0
	_origin = position
	_points = waypoints.duplicate()
	if not waypoint_nodes.is_empty():
		_points.clear()
		for path in waypoint_nodes:
			var marker := get_node_or_null(path) as Node2D
			if marker: _points.append(marker.global_position-global_position)
	if _points.size() < 2: push_error("Moving platform needs at least two points"); set_physics_process(false); return
	var shape := CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = data.size; shape.shape = rect; add_child(shape)
	actuator = InteractionActuator.new(); actuator.name = "Actuator"; add_child(actuator)
	var cfg := EnvironmentDeviceData.new(); cfg.initial_enabled = data.initially_enabled; cfg.initial_power = data.initially_powered; cfg.device_name = "Platform"; cfg.kind = EnvironmentDeviceData.Kind.GATE; cfg.visual = data.visual; cfg.size = data.size
	actuator.configure(cfg); actuator.links = links; actuator.input_sources = input_sources
	visual = InteractionVisual.new(); add_child(visual); visual.configure(cfg)
	actuator.changed.connect(func(value): visual.present(value))
	visual.present(actuator.output)
	reset()
func reset() -> void:
	position = _origin+_points[0]; _next = 1; _direction = 1; _wait = 0
	if actuator:
		actuator.enabled = data.initially_enabled; actuator.powered = data.initially_powered; actuator.inputs.clear(); actuator.publish_initial()
	reset_physics_interpolation()
func reverse() -> void:
	_direction *= -1
	_next = clampi(_next+_direction,0,_points.size()-1)
func _physics_process(delta: float) -> void:
	if actuator == null or not actuator.output or not SpellExecutor.is_authoritative(self): return
	if _wait > 0: _wait -= delta; return
	var destination := _origin+_points[_next]
	position = position.move_toward(destination,data.speed*delta)
	if position.distance_to(destination) > .01: return
	_wait = data.wait_seconds
	if data.route == MovingPlatformData.Route.ONE_SHOT and _next == _points.size()-1:
		actuator.receive(false,EnvironmentLink.Port.ENABLE); return
	if data.route == MovingPlatformData.Route.LOOP: _next = (_next+1)%_points.size()
	else:
		if _next == _points.size()-1 or _next == 0: _direction *= -1
		_next += _direction
