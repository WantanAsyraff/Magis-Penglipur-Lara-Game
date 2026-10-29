extends Node2D
var checks := 0
var failures := 0
var player: Player
var sandbox: Node2D
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+message)
func spawn_prop(slug: String, at: Vector2 = Vector2.ZERO, changes: Dictionary = {}) -> Node2D:
	var node: Node2D = load("res://components/environment/"+slug+".tscn").instantiate()
	if node is EnvironmentDevice:
		node.data = node.data.duplicate(true)
		for key in changes: node.data.set(key,changes[key])
	node.position = at; sandbox.add_child(node)
	if node is EnvironmentDevice or node is EnvironmentMovingPlatform: node.set_physics_process(false)
	return node
func connect_devices(source: Node2D, target: Node2D, port: EnvironmentLink.Port) -> void:
	var link := EnvironmentLink.new(); link.target = source.get_path_to(target); link.port = port
	source.actuator.links.append(link)
func reset_box() -> void:
	if is_instance_valid(sandbox): sandbox.free()
	sandbox = Node2D.new(); add_child(sandbox)
func press(action: String) -> void:
	var event := InputEventAction.new(); event.action = action; event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate(); event.pressed = false; get_viewport().push_input(event,true)
func _ready() -> void:
	await get_tree().process_frame
	Player_Global_Data.p_curr_health = 400; Player_Global_Data.p_curr_mana = 400
	Player_Global_Data.p_moveable = true; Player_Global_Data.combat_mode = true
	player = load("res://components/characters/player/player.tscn").instantiate(); add_child(player)
	player.set_physics_process(false); player.casting.set_physics_process(false)
	Player_Manager.players[Player_Manager.get_local_peer_id()] = player
	reset_box()
	for slug in ["light-switch","fuse-box","lamp","powered-gate","keyed-door","water-valve","water-tap","water-pump","water-tank","ceiling-fan","drainage-channel","pressure-switch","magis-receiver","training-turret","magis-breakable","electrical-relay","lever","moving-platform","water-volume","floating-crate"]:
		var prop := spawn_prop(slug,Vector2(3000+checks*300,0))
		check(is_instance_valid(prop),"Reusable scene instantiates: "+slug)
	await electrical()
	await water_devices()
	await pressure_and_magis()
	await hazards_and_motion()
	await authoring_and_delivery()
	print("ENVIRONMENT_INTERACTIONS: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
func electrical() -> void:
	reset_box()
	var fuse: EnvironmentDevice = spawn_prop("fuse-box",Vector2(600,0))
	var toggle: EnvironmentDevice = spawn_prop("light-switch",Vector2(100,0))
	var lamp: EnvironmentDevice = spawn_prop("lamp",Vector2(800,0))
	connect_devices(fuse,toggle,EnvironmentLink.Port.POWER); connect_devices(toggle,lamp,EnvironmentLink.Port.POWER)
	fuse.actuator.publish_initial(); toggle.actuator.publish_initial()
	check(not lamp.actuator.output,"Unpowered circuit starts off")
	toggle.interact(); check(toggle.actuator.enabled and not lamp.actuator.output,"Switch request is retained while fuse power is absent")
	fuse.interact(); check(lamp.actuator.output,"Restoring fuse power energizes a requested light")
	fuse.interact(); check(not lamp.actuator.output and toggle.actuator.enabled,"Fuse cuts output without erasing switch position")
	fuse.interact(); toggle.interact(); check(not lamp.actuator.output,"Switch can deactivate downstream light")
	var gate: EnvironmentDevice = spawn_prop("powered-gate",Vector2(1000,0),{"logic":EnvironmentDeviceData.Logic.NONE,"initial_enabled":false})
	connect_devices(toggle,gate,EnvironmentLink.Port.ENABLE)
	toggle.interact()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(gate.actuator.output and gate.collision.disabled,"Gate output opens real collision")
	toggle.interact(); await get_tree().physics_frame; await get_tree().physics_frame
	check(not gate.collision.disabled,"Deactivation restores gate collision")
	gate.data.auto_close = .2; gate.actuator.receive(true,EnvironmentLink.Port.ENABLE); gate._physics_process(.3)
	check(not gate.actuator.output,"Timed gate resets")
	var relay: EnvironmentDevice = spawn_prop("electrical-relay",Vector2(1400,0))
	relay.actuator.input_sources = [relay.get_path_to(fuse),relay.get_path_to(toggle)]
	relay.actuator.receive(true,EnvironmentLink.Port.INPUT,fuse)
	check(not relay.actuator.output,"AND relay waits for all configured sources")
	relay.actuator.receive(true,EnvironmentLink.Port.INPUT,toggle)
	check(relay.actuator.output,"AND relay energizes after both inputs")
	relay.actuator.logic = EnvironmentDeviceData.Logic.OR
	relay.actuator.receive(false,EnvironmentLink.Port.INPUT,fuse)
	check(relay.actuator.output,"OR relay retains output with one active source")
	connect_devices(relay,fuse,EnvironmentLink.Port.ENABLE); connect_devices(fuse,relay,EnvironmentLink.Port.ENABLE)
	relay.actuator.receive(false,EnvironmentLink.Port.INPUT,toggle)
	check(not relay.actuator.output,"Cyclic circuits terminate and reach a stable state")
	reset_box()
	var a: EnvironmentDevice = spawn_prop("light-switch",Vector2(100,0))
	var b: EnvironmentDevice = spawn_prop("light-switch",Vector2(160,0))
	await get_tree().physics_frame; await get_tree().physics_frame
	press("interact")
	check(a.actuator.enabled and not b.actuator.enabled,"One real interaction event activates only the nearest eligible prop")
func water_devices() -> void:
	reset_box()
	var source: EnvironmentDevice = spawn_prop("water-tank",Vector2(2000,0),{"initial_volume":80.0})
	var destination: EnvironmentDevice = spawn_prop("water-tank",Vector2(2300,0),{"initial_volume":0.0})
	var valve: EnvironmentDevice = spawn_prop("water-valve",Vector2(2600,0))
	var pump: EnvironmentDevice = spawn_prop("water-pump",Vector2(2900,0))
	pump.source_tank = pump.get_path_to(source); pump.destination_tank = pump.get_path_to(destination); pump.valves = [pump.get_path_to(valve)]
	valve.interact(); pump._physics_process(1)
	check(destination.volume == 0,"Unpowered pump cannot transfer")
	pump.actuator.receive(true,EnvironmentLink.Port.POWER); pump._physics_process(1)
	check(destination.volume == 15 and source.volume == 65,"Pump transfers actual source volume")
	check(source.volume+destination.volume == 80,"Water volume is conserved")
	valve.interact(); pump._physics_process(1)
	check(destination.volume == 15,"Closing the valve stops transfer")
	valve.interact(); destination.add_water(84); pump._physics_process(10)
	check(destination.volume == 100 and source.volume == 64,"Transfer respects destination capacity")
	pump.actuator.receive(false,EnvironmentLink.Port.POWER); pump._physics_process(1)
	check(source.volume == 64,"Power loss stops the pump")
	var drain: EnvironmentDevice = spawn_prop("drainage-channel",Vector2(3200,0))
	var debris: EnvironmentDevice = spawn_prop("magis-breakable",Vector2(3200,0))
	drain.source_tank = drain.get_path_to(source); drain.destination_tank = drain.get_path_to(destination); drain.blocking_debris = drain.get_path_to(debris)
	destination.take_water(100); drain._physics_process(1)
	check(drain.blocked and destination.volume == 0,"Debris blocks drainage")
	debris.hitbox.receive_damage(100,player); drain._physics_process(1)
	check(not drain.blocked and destination.volume == 20 and source.volume+drain.volume+destination.volume == 64,"Breaking debris restores conserved downstream flow")
	var water: WaterVolume2D = spawn_prop("water-volume",Vector2(4000,0))
	destination.water_volume = destination.get_path_to(water); destination.add_water(30)
	check(is_equal_approx(water.fill,.5),"Tank volume drives a real water surface")
	var crate: EnvironmentCrate = spawn_prop("floating-crate",Vector2(4000,100))
	crate.freeze = true
	await get_tree().physics_frame; await get_tree().physics_frame
	check(water.contains_body(crate),"Water volume detects a floating object's immersed body")
	var before := water.surface_y(); destination.add_water(50)
	check(water.surface_y() < before,"Filling raises the water surface")
func pressure_and_magis() -> void:
	reset_box()
	var plate: EnvironmentDevice = spawn_prop("pressure-switch",Vector2(2500,0))
	var crate: EnvironmentCrate = spawn_prop("floating-crate",Vector2(2500,-40))
	crate.freeze = true; crate.mass = 10
	plate._entered(crate); plate._entered(crate); plate._physics_process(.3)
	check(plate.total_weight() == 10 and not plate.actuator.output,"Duplicate body entries do not double-count a light object")
	crate.mass = 50; plate._physics_process(.3)
	check(plate.actuator.output,"Sufficient mass activates the pressure switch")
	plate._exited(crate); plate._physics_process(.3)
	check(not plate.actuator.output,"Removing weight deactivates a hold plate")
	var receiver: EnvironmentDevice = spawn_prop("magis-receiver",Vector2(180,0))
	var gate: EnvironmentDevice = spawn_prop("powered-gate",Vector2(800,0),{"logic":EnvironmentDeviceData.Logic.NONE,"initial_enabled":false})
	connect_devices(receiver,gate,EnvironmentLink.Port.ENABLE)
	var force_spell: SpellData = load("res://data/magis/spells/phys-force.tres")
	SpellExecutor.new().execute(SpellCastContext.new(player,force_spell),receiver)
	check(not receiver.actuator.output,"Cooled receiver rejects an unrelated damage/impulse payload")
	var chill: SpellData = load("res://data/magis/spells/thermal-kinetic.tres")
	var context := SpellCastContext.new(player,chill)
	SpellExecutor.new().execute(context,receiver)
	check(receiver.actuator.output and gate.actuator.output,"Kinetic Chill's actual cooled effect activates a linked gate")
	check(receiver.receiver.hits == 1,"One cast with multiple effects counts once")
	check(CombatFactions.faction(receiver) == &"neutral" and not player.target_lock.eligible(receiver),"Puzzle receivers remain neutral and absent from Q targeting")
	receiver.reset(); await get_tree().physics_frame; await get_tree().physics_frame
	press("environment_target")
	check(player.environment_target.current() == receiver,"Separate environment action explicitly selects the receiver")
	Player_Global_Data.learned_spells.assign([chill]); Player_Global_Data.equipped_spells.assign([chill])
	player._cast_resolved(chill); player.casting._physics_process(chill.cast_time+.01)
	for i in 30: await get_tree().physics_frame
	check(receiver.actuator.output,"A production player cast and real projectile impact activate the neutral receiver")
	var key_gate: EnvironmentDevice = spawn_prop("keyed-door",Vector2(3500,0))
	Player_Global_Data.set_meta("keys",["environment-lab-key"])
	key_gate.interact()
	check(key_gate.actuator.output and not WorldKeyAccess.has_key("environment-lab-key"),"Keyed environment door reuses the existing key consumption contract")
func hazards_and_motion() -> void:
	reset_box(); player.environment_target.clear(); player.position = Vector2.ZERO
	var turret: EnvironmentDevice = spawn_prop("training-turret",Vector2(400,0))
	turret._physics_process(.01)
	check(turret.turret_state == &"warning" and turret.shots_fired == 0,"Turret warns before firing")
	turret._physics_process(1)
	check(turret.shots_fired == 1 and turret.turret_state == &"cooldown","Turret dispatches an actual projectile after windup")
	var projectile := false
	for node in get_tree().get_nodes_in_group("spell_projectile"):
		if node.source == turret: projectile = true
	check(projectile,"Turret uses the existing MagicProjectile engine")
	turret.actuator.receive(false,EnvironmentLink.Port.POWER)
	check(turret.turret_state == &"disabled","Power loss clears turret warning/cooldown state")
	turret._physics_process(5); check(turret.shots_fired == 1,"Unpowered turret cannot fire")
	turret.hitbox.receive_damage(1000,player); turret._physics_process(10)
	check(turret.get_meta("combat_dead",false) and turret.shots_fired == 1,"Destroyed turret cannot schedule another shot")
	var fan: EnvironmentDevice = spawn_prop("ceiling-fan",Vector2(2000,0))
	fan._physics_process(.5); check(fan.speed > 0 and fan.visual.angle > 0,"Powered fan accelerates and rotates")
	fan.actuator.receive(false,EnvironmentLink.Port.POWER); fan._physics_process(2)
	check(fan.speed == 0,"Unpowered fan decelerates to rest")
	var platform: EnvironmentMovingPlatform = spawn_prop("moving-platform",Vector2(3000,0))
	platform.actuator.receive(true,EnvironmentLink.Port.ENABLE); platform._physics_process(.5)
	await get_tree().physics_frame; await get_tree().physics_frame
	var position_mid := platform.position
	check(position_mid.y < 0,"Platform moves its actual physics body")
	platform.actuator.receive(false,EnvironmentLink.Port.POWER); platform._physics_process(1)
	check(platform.position == position_mid,"Platform power interruption holds position halfway")
	platform.actuator.receive(true,EnvironmentLink.Port.POWER); platform._physics_process(.5)
	await get_tree().physics_frame; await get_tree().physics_frame
	check(platform.position.y < position_mid.y,"Restored power resumes from the held position")

func authoring_and_delivery() -> void:
	reset_box(); player.position = Vector2.ZERO
	var receiver: EnvironmentDevice = spawn_prop("magis-receiver",Vector2(180,0))
	var chill: SpellData = load("res://data/magis/spells/thermal-kinetic.tres")
	receiver.receiver.rule = load("res://data/environment/three-hit-rule.tres")
	for i in 2: SpellExecutor.new().execute(SpellCastContext.new(player,chill),receiver)
	check(not receiver.actuator.output and receiver.receiver.hits == 2,"Hit-count receiver counts distinct casts rather than individual payload effects")
	SpellExecutor.new().execute(SpellCastContext.new(player,chill),receiver)
	check(receiver.actuator.output,"Third qualifying cast activates configured hit-count receiver")
	receiver.reset(); receiver.receiver.rule = load("res://data/environment/charge-rule.tres")
	var charge_rule := receiver.receiver.rule
	charge_rule = charge_rule.duplicate(); charge_rule.required_charge = 24; receiver.receiver.rule = charge_rule
	SpellExecutor.new().execute(SpellCastContext.new(player,chill),receiver)
	check(not receiver.actuator.output,"Charge receiver waits for sufficient authored mana energy")
	SpellExecutor.new().execute(SpellCastContext.new(player,chill),receiver)
	check(receiver.actuator.output and receiver.receiver.charge == 24,"Independent casts accumulate charge without duplicating payloads")
	receiver.reset(); receiver.receiver.rule = load("res://data/environment/cooled-rule.tres")
	var direct := chill.duplicate(true); direct.delivery = SpellData.Delivery.DIRECT_TARGET
	var context := SpellCastContext.new(player,direct); context.targets.assign([receiver])
	check(SpellDelivery.dispatch(context) and receiver.actuator.output,"Direct-target delivery reaches an explicit neutral environmental receiver")
	receiver.reset(); receiver.receiver.rule = load("res://data/environment/cooled-rule.tres")
	var area := chill.duplicate(true); area.delivery = SpellData.Delivery.AREA_BURST; area.aoe_spell_radius = 300
	check(SpellDelivery.apply_area(SpellCastContext.new(player,area),player.global_position) and receiver.actuator.output,"Area delivery uses shared Hitbox group for environmental effects")
	receiver.reset(); receiver.receiver.rule = load("res://data/environment/cooled-rule.tres")
	var beam := chill.duplicate(true); beam.delivery = SpellData.Delivery.BEAM; beam.target_range = 500; beam.beam_width = 60
	check(SpellDelivery.apply_area(SpellCastContext.new(player,beam),player.global_position,true) and receiver.actuator.output,"Beam delivery reaches neutral receivers through the existing executor")
	receiver.reset(); receiver.receiver.rule = load("res://data/environment/cooled-rule.tres")
	receiver.hitbox.apply_status("cooled",3,{},"prior-cast",ActiveEffectManager.StackPolicy.REFRESH,1)
	var slow := ApplyStatusEffect.new(); slow.status = "slow"; slow.magnitude = .5
	var unrelated := chill.duplicate(true); unrelated.effects.assign([slow])
	SpellExecutor.new().execute(SpellCastContext.new(player,unrelated),receiver)
	check(not receiver.actuator.output,"A stale cooled status cannot make a different incoming status satisfy the rule")
	var collision_before := receiver.collision.shape
	var cfg := receiver.data.duplicate(true)
	cfg.visual = EnvironmentVisualData.new(); cfg.visual.texture = GradientTexture2D.new()
	receiver.visual.configure(cfg)
	check(receiver.visual._art is Sprite2D,"Texture2D swaps the procedural placeholder through Inspector data")
	var frames_ := SpriteFrames.new(); frames_.rename_animation(&"default",&"idle")
	cfg.visual.texture = null; cfg.visual.frames = frames_
	receiver.visual.configure(cfg); receiver.visual.present(true)
	check(receiver.visual._art is AnimatedSprite2D and receiver.visual._art.animation == &"idle","Missing active SpriteFrames animation falls back to idle")
	var root := Node2D.new(); root.name = "CustomVisual"
	var animator := AnimationPlayer.new(); animator.name = "AnimationPlayer"; root.add_child(animator); animator.owner = root
	var library := AnimationLibrary.new(); var idle := Animation.new(); idle.length = 1; library.add_animation(&"idle",idle); animator.add_animation_library(&"",library)
	var packed := PackedScene.new(); packed.pack(root); root.free()
	cfg.visual.frames = null; cfg.visual.visual_scene = packed
	receiver.visual.configure(cfg); receiver.visual.present(true)
	check(receiver.visual._art.name == "CustomVisual" and receiver.visual._art.get_node("AnimationPlayer").current_animation == "idle","Custom PackedScene and AnimationPlayer support missing-animation fallback")
	check(receiver.collision.shape == collision_before,"Replacing artwork preserves gameplay collision")
	var bad := EnvironmentDeviceData.new(); bad.valve_opening = NAN
	check(not bad.validate().is_empty(),"Invalid nonfinite valve configuration fails validation")
	var breakable: EnvironmentDevice = spawn_prop("magis-breakable",Vector2(1000,0),{"respawn_seconds":.2})
	breakable.hitbox.receive_damage(999,player); await get_tree().physics_frame; await get_tree().physics_frame
	check(breakable.collision.disabled,"Destructible damage removes its real blocking collision")
	breakable._physics_process(.3); await get_tree().physics_frame; await get_tree().physics_frame
	check(not breakable.get_meta("combat_dead",false) and not breakable.collision.disabled,"Configured transient breakables respawn with restored collision and health")
