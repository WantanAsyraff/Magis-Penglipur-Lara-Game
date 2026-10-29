class_name EnvironmentDevice extends CharacterBody2D
signal activated(active: bool)
signal broken
signal full
signal overflow
signal empty
signal volume_changed(volume: float)
@export var data: EnvironmentDeviceData
@export var links: Array[EnvironmentLink] = []
@export var input_sources: Array[NodePath] = []
@export var source_tank: NodePath
@export var destination_tank: NodePath
@export var valves: Array[NodePath] = []
@export var light_targets: Array[NodePath] = []
@export var water_volume: NodePath
@export var blocking_debris: NodePath
@export var timeline: String = ""
var actuator: InteractionActuator
var receiver: InteractionReceiver
var visual: InteractionVisual
var hitbox: HitboxComponent
var collision: CollisionShape2D
var detector: DetectionComponent
var sensor: Area2D
var volume: float = 0
var health: float = 0
var blocked := false
var speed := 0.0
var _timer := 0.0
var _press_time := 0.0
var _release_time := 0.0
var _pressed := false
var _fired_once := false
var _bodies: Dictionary = {}
var _initial_position := Vector2.ZERO
var turret_state: StringName = &"disabled"
var turret_target: Node2D
var shots_fired := 0
var _shot_timer := 0.0
var _shot_epoch := 0
var _overflowing := false
func _ready() -> void:
	if data == null: data = EnvironmentDeviceData.new()
	var errors := data.validate()
	if not errors.is_empty(): push_error(str(errors)); set_physics_process(false); return
	_initial_position = position
	collision_layer = 16
	collision_mask = 16
	set_meta("faction_id",&"enemy" if data.kind == EnvironmentDeviceData.Kind.TURRET else &"neutral")
	set_meta("spell_team",get_meta("faction_id"))
	for capability in data.capabilities: set_meta(StringName(String(capability).replace("-","_")),true)
	collision = CollisionShape2D.new(); collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new(); shape.size = data.size; collision.shape = shape; add_child(collision)
	actuator = InteractionActuator.new(); actuator.name = "Actuator"; add_child(actuator)
	actuator.links = links; actuator.input_sources = input_sources
	actuator.configure(data)
	visual = get_node_or_null("Visual") as InteractionVisual
	if visual == null:
		visual = InteractionVisual.new(); visual.name = "Visual"; add_child(visual)
	visual.configure(data)
	hitbox = HitboxComponent.new(); hitbox.name = "HitboxComponent"; add_child(hitbox)
	hitbox.has_mana = false
	hitbox.receives_knockback = data.kind == EnvironmentDeviceData.Kind.BREAKABLE
	hitbox.damage_taken.connect(_damage)
	if data.kind != EnvironmentDeviceData.Kind.TURRET: remove_from_group("combat_target")
	var target := EnvironmentalTarget.new(); target.name = "EnvironmentalTarget"
	target.targetable = data.kind in [EnvironmentDeviceData.Kind.RECEIVER,EnvironmentDeviceData.Kind.BREAKABLE,EnvironmentDeviceData.Kind.TURRET] or (data.rule != null and data.rule.event in [InteractionRule.Event.SPELL,InteractionRule.Event.DAMAGE,InteractionRule.Event.STATUS,InteractionRule.Event.IMPULSE,InteractionRule.Event.PROJECTILE])
	add_child(target)
	receiver = InteractionReceiver.new(); receiver.name = "InteractionReceiver"; add_child(receiver)
	receiver.rule = data.rule
	receiver.activated.connect(_trigger)
	hitbox.knocked_back.connect(_impulse)
	receiver.progress.connect(func(_hits,_charge): visual.present(actuator.output,&"charging"))
	var caption := Label.new(); caption.name = "Caption"; caption.text = data.device_name; caption.position = Vector2(-data.size.x/2,data.size.y/2+8); caption.add_theme_font_size_override("font_size",16); add_child(caption)
	var prompt := Label.new(); prompt.name = "InteractLabel"; prompt.position = Vector2(-100,-data.size.y/2-32); prompt.hide(); add_child(prompt)
	if data.manual_interaction and data.kind in [EnvironmentDeviceData.Kind.SWITCH,EnvironmentDeviceData.Kind.FUSE,EnvironmentDeviceData.Kind.LEVER,EnvironmentDeviceData.Kind.VALVE,EnvironmentDeviceData.Kind.PUMP,EnvironmentDeviceData.Kind.GATE]:
		detector = DetectionComponent.new(); detector.interaction_radius = data.interaction_radius; detector.interact_label_text = "Interact · "+data.device_name; add_child(detector); detector.interacted.connect(interact)
	if data.kind in [EnvironmentDeviceData.Kind.PLATE,EnvironmentDeviceData.Kind.FAN] or (data.rule and data.rule.event in [InteractionRule.Event.ENTER,InteractionRule.Event.EXIT,InteractionRule.Event.CONTACT]):
		sensor = Area2D.new(); sensor.name = "Sensor"; sensor.collision_mask = 17; sensor.collision_layer = 0
		var sensor_shape := CollisionShape2D.new(); var rect := RectangleShape2D.new()
		rect.size = Vector2(data.size.x,maxf(30,data.size.y+30)) if data.kind != EnvironmentDeviceData.Kind.FAN else Vector2(300,450)
		sensor_shape.shape = rect
		if data.kind == EnvironmentDeviceData.Kind.PLATE: sensor_shape.position.y = -20
		if data.kind == EnvironmentDeviceData.Kind.FAN: sensor_shape.position.y = 200
		sensor.add_child(sensor_shape); add_child(sensor)
		sensor.body_entered.connect(_entered); sensor.body_exited.connect(_exited)
	if data.kind == EnvironmentDeviceData.Kind.LIGHT:
		var light := PointLight2D.new(); light.name = "Bulb"
		var texture := GradientTexture2D.new(); texture.width = 256; texture.height = 256; texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(.5,.5); texture.fill_to = Vector2(1,.5)
		var gradient := Gradient.new(); gradient.colors = PackedColorArray([Color(1,1,1,.8),Color(1,1,1,0)]); texture.gradient = gradient
		light.texture = texture; light.texture_scale = 2; light.color = Color(1,.86,.55); add_child(light)
		light_targets.append(NodePath("Bulb"))
	actuator.changed.connect(_state_changed)
	reset(false)
	if data.persistent:
		if WorldPersistence.has_state(self,"broken"): _break(false)
		elif WorldPersistence.has_state(self,"activated"):
			actuator.enabled = true; actuator.unlocked = true
	_state_changed(actuator.effective())
	actuator.call_deferred("publish_initial")
func interact() -> void:
	if not data.manual_interaction or not SpellExecutor.is_authoritative(self) or get_meta("combat_dead",false): return
	if data.kind == EnvironmentDeviceData.Kind.GATE and not actuator.unlocked:
		if not WorldKeyAccess.has_key(data.key_id): return
		if data.consume_key: WorldKeyAccess.consume(data.key_id)
		actuator.unlocked = true
	if data.rule and data.rule.event != InteractionRule.Event.INTERACT: return
	if data.rule: receiver.receive_event(InteractionRule.Event.INTERACT)
	else: _trigger()
func _trigger() -> void:
	if get_meta("combat_dead",false) or (data.persistent and actuator.enabled): return
	if data.kind == EnvironmentDeviceData.Kind.RECEIVER or (data.rule and data.rule.event != InteractionRule.Event.INTERACT):
		actuator.receive(true,EnvironmentLink.Port.ENABLE)
	else: actuator.toggle()
	if actuator.enabled:
		_timer = maxf(data.activation_seconds,data.auto_close)
		if data.persistent and not SaveManager.loading: WorldPersistence.mark(self,"activated")
		if not timeline.is_empty() and not SaveManager.loading and Dialogic.current_timeline == null: Dialogic.start(timeline)
func _state_changed(value: bool) -> void:
	if value: _timer = maxf(data.activation_seconds,data.auto_close)
	visual.present(value,&"broken" if get_meta("combat_dead",false) else (&"blocked" if blocked else &""))
	if data.kind == EnvironmentDeviceData.Kind.GATE: collision.set_deferred("disabled",value or get_meta("combat_dead",false))
	if data.kind in [EnvironmentDeviceData.Kind.LIGHT,EnvironmentDeviceData.Kind.SWITCH,EnvironmentDeviceData.Kind.FUSE]:
		for path in light_targets:
			var light := get_node_or_null(path) as Light2D
			if light: light.enabled = value
	if data.kind == EnvironmentDeviceData.Kind.TURRET and not value: _stop_turret()
	activated.emit(value)
func _impulse(impulse: Vector2) -> void:
	receiver.receive_event(InteractionRule.Event.IMPULSE,impulse.length())
	if data.kind != EnvironmentDeviceData.Kind.BREAKABLE or get_meta("combat_dead",false): return
	var motion := get_node_or_null("SpellMotionImpulse") as SpellMotionImpulse
	if motion == null:
		motion = SpellMotionImpulse.new(); motion.name = "SpellMotionImpulse"; add_child(motion)
	motion.impulse = (motion.impulse+impulse).limit_length(1000); motion.remaining = .25
func _damage(amount: float) -> void:
	if not SpellExecutor.is_authoritative(self) or get_meta("combat_dead",false): return
	if data.kind not in [EnvironmentDeviceData.Kind.BREAKABLE,EnvironmentDeviceData.Kind.TURRET] or not data.destructible: return
	health = maxf(0,health-amount)
	visual.present(actuator.output,&"damaged")
	if health <= 0: _break()
func _break(persist: bool = true) -> void:
	if get_meta("combat_dead",false): return
	set_meta("combat_dead",true)
	collision.set_deferred("disabled",true)
	actuator.receive(false,EnvironmentLink.Port.ENABLE)
	visual.present(false,&"broken")
	_stop_turret()
	CombatLifecycle.cleanup(self)
	if persist and data.persistent: WorldPersistence.mark(self,"broken")
	if persist and not data.loot.is_empty():
		var loot := EnemyLootComponent.new(); add_child(loot); loot.loot_table = data.loot; loot._on_enemy_died()
	broken.emit()
	if data.respawn_seconds > 0 and not data.persistent: _timer = data.respawn_seconds
func reset(propagate: bool = true) -> void:
	set_meta("combat_dead",false)
	position = _initial_position
	velocity = Vector2.ZERO
	health = data.max_health
	volume = clampf(data.initial_volume,0,data.capacity)
	blocked = false; speed = 0; _timer = 0; _press_time = 0; _release_time = 0; _pressed = false; _fired_once = false
	var motion := get_node_or_null("SpellMotionImpulse")
	if motion: motion.queue_free()
	receiver.reset(); hitbox.clear_all_effects(); actuator.inputs.clear(); actuator.configure(data)
	collision.set_deferred("disabled",data.kind not in [EnvironmentDeviceData.Kind.GATE,EnvironmentDeviceData.Kind.BREAKABLE,EnvironmentDeviceData.Kind.TURRET,EnvironmentDeviceData.Kind.TANK,EnvironmentDeviceData.Kind.RECEIVER])
	_stop_turret(); CombatLifecycle.cleanup(self)
	_sync_water()
	_state_changed(actuator.output)
	if propagate: actuator.publish_initial()
func add_water(amount: float) -> float:
	if not SpellExecutor.is_authoritative(self) or not is_finite(amount) or amount <= 0: return 0
	var moved := minf(amount,data.capacity-volume)
	var before := volume
	volume += moved
	_sync_water()
	if before < data.capacity and volume >= data.capacity: full.emit()
	return moved
func take_water(amount: float) -> float:
	if not SpellExecutor.is_authoritative(self) or not is_finite(amount) or amount <= 0: return 0
	var moved := minf(amount,volume)
	var before := volume
	volume -= moved
	_sync_water()
	if before > 0 and volume <= 0: empty.emit()
	return moved
func _sync_water() -> void:
	if visual: visual.level = volume/data.capacity; visual.queue_redraw()
	var water := get_node_or_null(water_volume) as WaterVolume2D if not water_volume.is_empty() else null
	if water: water.set_fill(volume/data.capacity)
	volume_changed.emit(volume)
func _transfer(delta: float) -> void:
	var source := get_node_or_null(source_tank) as EnvironmentDevice if not source_tank.is_empty() else null
	var destination := get_node_or_null(destination_tank) as EnvironmentDevice if not destination_tank.is_empty() else null
	if source == null or destination == null or source == destination: return
	var opening := data.valve_opening if data.kind == EnvironmentDeviceData.Kind.VALVE else 1.0
	for path in valves:
		var valve := get_node_or_null(path) as EnvironmentDevice
		if valve == null or not valve.actuator.output: return
		opening = minf(opening,valve.data.valve_opening)
	var amount := minf(data.flow_rate*delta*opening,minf(source.volume,destination.data.capacity-destination.volume))
	if amount > 0: destination.add_water(source.take_water(amount))
func _drain(delta: float) -> void:
	var source := get_node_or_null(source_tank) as EnvironmentDevice if not source_tank.is_empty() else null
	var destination := get_node_or_null(destination_tank) as EnvironmentDevice if not destination_tank.is_empty() else null
	if source == null or destination == null or source == self or destination == self or source == destination: return
	add_water(source.take_water(minf(data.flow_rate*delta,data.capacity-volume)))
	if not blocked: destination.add_water(take_water(minf(data.flow_rate*delta,destination.data.capacity-destination.volume)))
	var overflowing := blocked and volume >= data.capacity
	if overflowing and not _overflowing: overflow.emit()
	_overflowing = overflowing
func _entered(body: Node2D) -> void:
	if not (body is Player or body is RigidBody2D or (body is CharacterBody2D and body.get_meta("spell_team",&"") == &"enemy")): return
	_bodies[body.get_instance_id()] = weakref(body)
	receiver.receive_event(InteractionRule.Event.ENTER)
	receiver.receive_event(InteractionRule.Event.CONTACT,body.mass if body is RigidBody2D else data.player_weight)
func _exited(body: Node2D) -> void:
	_bodies.erase(body.get_instance_id())
	receiver.receive_event(InteractionRule.Event.EXIT)
func total_weight() -> float:
	var result := 0.0
	for id in _bodies.keys():
		var body = _bodies[id].get_ref()
		if not is_instance_valid(body): _bodies.erase(id); continue
		if body is RigidBody2D: result += body.mass
		elif body is Player: result += data.player_weight
	return result
func _pressure(delta: float) -> void:
	var enough := total_weight() >= data.minimum_weight
	_press_time = _press_time+delta if enough else 0
	_release_time = _release_time+delta if not enough else 0
	if enough and not _pressed and _press_time >= data.activation_delay:
		_pressed = true
		if data.plate_mode == EnvironmentDeviceData.PlateMode.HOLD: actuator.receive(true,EnvironmentLink.Port.ENABLE)
		elif data.plate_mode == EnvironmentDeviceData.PlateMode.TOGGLE: actuator.toggle()
		elif not _fired_once:
			_fired_once = true; actuator.receive(true,EnvironmentLink.Port.ENABLE)
			if data.plate_mode == EnvironmentDeviceData.PlateMode.TIMED: _timer = maxf(.1,data.activation_seconds)
		receiver.receive_event(InteractionRule.Event.PRESSURE,total_weight())
	if not enough and _pressed and _release_time >= data.deactivation_delay:
		_pressed = false
		if data.plate_mode == EnvironmentDeviceData.PlateMode.HOLD: actuator.receive(false,EnvironmentLink.Port.ENABLE)
		if data.plate_mode == EnvironmentDeviceData.PlateMode.TIMED: _fired_once = false
func _physics_process(delta: float) -> void:
	if data == null or not SpellExecutor.is_authoritative(self): return
	if _timer > 0:
		_timer -= delta
		if _timer <= 0:
			if get_meta("combat_dead",false): reset()
			else: actuator.receive(false,EnvironmentLink.Port.ENABLE)
	if get_meta("combat_dead",false): return
	match data.kind:
		EnvironmentDeviceData.Kind.PLATE: _pressure(delta)
		EnvironmentDeviceData.Kind.PUMP:
			if actuator.output: _transfer(delta)
		EnvironmentDeviceData.Kind.DRAIN:
			var debris := get_node_or_null(blocking_debris) if not blocking_debris.is_empty() else null
			blocked = is_instance_valid(debris) and not debris.get_meta("combat_dead",false) and (debris as Node2D).global_position.distance_to(global_position) < data.size.x
			if actuator.output: _drain(delta)
			visual.present(actuator.output,&"blocked" if blocked else &"")
		EnvironmentDeviceData.Kind.FAN:
			speed = move_toward(speed,data.fan_speed if actuator.output else 0,data.fan_acceleration*delta)
			visual.angle += speed*delta
			if actuator.output and data.airflow_enabled and sensor:
				for body in sensor.get_overlapping_bodies():
					if body is RigidBody2D and body.mass <= data.airflow_max_mass: body.apply_central_force(data.airflow*body.mass)
					elif body is Player and data.player_airflow:
						var motion := body.get_node_or_null("SpellMotionImpulse") as SpellMotionImpulse
						if motion == null:
							motion = SpellMotionImpulse.new(); motion.name = "SpellMotionImpulse"; body.add_child(motion)
						motion.impulse = (motion.impulse+data.airflow*delta).limit_length(1000); motion.remaining = .1
		EnvironmentDeviceData.Kind.VALVE:
			visual.angle += delta*6 if actuator.output else 0
			if actuator.output: _transfer(delta)
		EnvironmentDeviceData.Kind.TURRET: _turret(delta)
	var caption := get_node_or_null("Caption") as Label
	if caption:
		caption.text = data.device_name+ (" · %.0f/%.0f L" % [volume,data.capacity] if data.kind in [EnvironmentDeviceData.Kind.TANK,EnvironmentDeviceData.Kind.DRAIN] else (" · Unpowered" if not actuator.powered else (" · Blocked" if blocked else "")))
	visual.queue_redraw()
func _stop_turret() -> void:
	_shot_epoch += 1
	turret_state = &"disabled"
	_shot_timer = 0
	turret_target = null
	if is_inside_tree(): CombatLifecycle.cleanup(self)
func _turret(delta: float) -> void:
	if not actuator.output: return
	if turret_state == &"disabled": turret_state = &"idle"
	_shot_timer = maxf(0,_shot_timer-delta)
	if turret_state == &"cooldown" and _shot_timer > 0: return
	var selected: Node2D
	var best := data.attack_range
	for candidate in get_tree().get_nodes_in_group("combat_target"):
		if not candidate is Node2D or candidate == self or candidate.get_meta("combat_dead",false) or CombatFactions.relation(self,candidate) >= 0: continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance >= best: continue
		var exclude: Array[RID] = [get_rid()]
		if candidate is CollisionObject2D: exclude.append(candidate.get_rid())
		var ray := PhysicsRayQueryParameters2D.create(global_position,candidate.global_position,16,exclude)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): selected = candidate; best = distance
	if selected == null:
		turret_state = &"acquiring"; turret_target = null; return
	if turret_state != &"warning" or turret_target != selected:
		turret_target = selected; turret_state = &"warning"; _shot_timer = data.warning_seconds
		visual.present(true,&"warning")
	visual.angle = (selected.global_position-global_position).angle()
	if _shot_timer > 0: return
	var context := SpellCastContext.new(self,data.turret_spell)
	context.direction = global_position.direction_to(selected.global_position)
	context.source_position = global_position+context.direction*(data.size.x/2+12)
	context.modifiers.damage_multiplier = data.outgoing_damage
	if data.training_nonlethal: context.modifiers.nonlethal = true
	turret_state = &"firing"
	if SpellDelivery.dispatch(context): shots_fired += 1
	turret_state = &"cooldown"; _shot_timer = data.firing_interval; visual.present(true,&"firing")
