extends Node
var checks := 0
var failures := 0
var world: Node2D
var player: Player
const BASE := "res://components/environment/destruction/"
const PRESETS := ["wooden-crate", "glass-barrier", "stone-block", "fragile-platform", "explosive-barrel", "poison-canister", "fragmentation-container", "minion-pod"]
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func prop(slug: String = "wooden-crate", at: Vector2 = Vector2.ZERO) -> DestructibleObject:
	var node := load(BASE + "presets/" + slug + ".tscn").instantiate() as DestructibleObject
	node.config = node.config.duplicate(true)
	node.position = at
	world.add_child(node)
	return node
func component(node: Node) -> DestructibleComponent:
	return node.get_node("DestructibleComponent") as DestructibleComponent
func frames(count: int = 2) -> void:
	for index in count: await get_tree().physics_frame
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func _ready() -> void:
	await get_tree().process_frame
	if "--quest-test-mode" not in OS.get_cmdline_user_args(): get_tree().quit(2); return
	QuestManager.persistence_enabled = false
	world = Node2D.new(); add_child(world)
	for slug in PRESETS:
		var node := prop(slug, Vector2(checks * 500, 0))
		check(node.config.validate().is_empty(), "Working preset validates: " + slug + " " + "; ".join(node.config.validate()))
		check(component(node).health == node.config.max_health, "Preset initializes durability: " + slug)
	await frames()
	await core()
	await integration()
	await explosions()
	await hazards_and_shrapnel()
	await spawning_and_events()
	await chains_and_limits()
	await persistence()
	await edge_cases()
	await additional_coverage()
	QuestManager.persistence_enabled = false
	QuestManager._save_timer.stop(); SaveManager._autosave_pending = false
	print("DESTRUCTION_FRAMEWORK: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func isolate() -> void:
	if is_instance_valid(world): world.free()
	world = Node2D.new(); add_child(world)
	await frames()
func source() -> Node2D:
	var node := Node2D.new(); node.set_meta("spell_team", &"player"); node.set_meta("quest_owner_id", QuestManager.active_owner_id)
	world.add_child(node)
	return node
func spell(amount: float = 5.0) -> SpellData:
	var definition := SpellData.new(); definition.spell_id = "destruction_test"; definition.spell_name = "Authored test"
	definition.delivery = SpellData.Delivery.DIRECT_TARGET
	var effect := DamageEffect.new(); effect.amount = amount; definition.effects = [effect]
	return definition
func core() -> void:
	await isolate()
	var node := prop(); var c := component(node); node.config.behaviors.clear()
	check(c.apply_damage(6) and c.health == 14 and c.current_state.state_id == &"damaged", "Damage selects configured 75 percent state")
	c.apply_damage(7)
	check(c.health == 7 and c.current_state.state_id == &"critical", "Critical threshold selects the correct state")
	check(c.repair(4) and c.health == 11 and c.current_state.state_id == &"damaged", "Repair reverses damage states")
	check(c.repair(100) and c.health == 20 and not c.repair(1), "Repair clamps health and rejects no-op")
	check(c.set_health(5) and c.health == 5, "set_health sets exact durability without applying material twice")
	node.config.invulnerable = true
	check(not c.apply_damage(100) and not c.destroy(), "Invulnerability blocks damage and scripted destruction")
	node.config.invulnerable = false; node.config.enabled = false
	check(not c.apply_damage(100) and not c.destroy(), "Disabled destructibles cannot be destroyed")
	node.config.enabled = true
	check(not c.apply_damage(-1) and not c.apply_damage(NAN) and not c.set_health(INF), "Non-finite and negative inputs are rejected")
	var counts := [0,0,0]
	c.destruction_started.connect(func(_ctx): counts[0] += 1)
	c.destroyed.connect(func(_ctx): counts[1] += 1)
	c.destruction_completed.connect(func(_ctx): counts[2] += 1)
	check(c.destroy() and not c.destroy() and not c.apply_damage(3), "Simultaneous lethal attempts execute destruction once")
	check(counts == [1,1,0] and c.animation_in_progress, "Lifecycle signals distinguish start from animation completion")
	await wait(0.55)
	check(counts == [1,1,1] and c.effects_executed and not c.animation_in_progress, "Bounded missing-animation fallback finishes exactly once")
	check(node.get_node("SolidCollision").disabled, "Destroyed solid collision is disabled safely")
	check(c.reset_destructible() and not c.is_destroyed() and c.health == 20, "Explicit reset starts a new generation")
	await frames()
	check(not node.get_node("SolidCollision").disabled, "Reset restores solid collision")
	node.config.destroy_on_zero_health = false
	c.apply_damage(100)
	check(c.health == 0 and not c.is_destroyed(), "Zero-health scripted objects can opt out of auto destruction")
	check(c.destroy() and c.is_destroyed(), "A scripted zero-health object can later enter the ordinary destruction lifecycle")
	node.config.destroy_on_zero_health = true; c.reset_destructible()
	node.config.material.thermal_multiplier = 2.0
	var damage := EnvironmentalDamage.new(); damage.kind = EnvironmentalDamage.Kind.THERMAL
	c.apply_damage(3,damage)
	check(c.health == 14, "Typed thermal damage uses the authored material multiplier")
	var invalid := node.config.duplicate(true) as DestructibleConfig
	invalid.states.append(invalid.states[0])
	check(not invalid.validate().is_empty(), "Duplicate thresholds and state IDs fail authoring validation")
	invalid = node.config.duplicate(true); invalid.states[0].health_threshold_ratio = -1
	check(not invalid.validate().is_empty(), "Out-of-range thresholds fail authoring validation")
	var visual := node.get_node("VisualRoot") as DestructibleVisualController
	var texture := GradientTexture2D.new()
	node.config.states[0].sprite_texture = texture; c.reset_destructible()
	check(visual.sprite.texture == texture and visual.sprite.visible, "State texture drives the exposed Sprite2D")
	var frames_data := SpriteFrames.new(); frames_data.add_animation(&"idle"); frames_data.add_frame(&"idle",texture)
	node.config.states[0].sprite_frames = frames_data; node.config.states[0].animation_name = &"missing"
	c.reset_destructible()
	check(visual.animated.visible and visual.animated.animation == &"idle", "Missing authored sprite animation falls back safely to idle")
	check(visual.play_hook(&"hit") and visual.play_hook(&"hit"), "AnimationPlayer hit hooks can restart on repeated hits")
	var shared := load(BASE + "presets/stone-block.tres") as DestructibleConfig
	var a := prop("stone-block",Vector2(500,0)); var b := prop("stone-block",Vector2(800,0))
	component(a).apply_damage(20)
	check(component(b).health == 150 and shared.max_health == 150, "Runtime health never mutates shared definitions")
func integration() -> void:
	await isolate()
	var actor := source(); var node := prop(); node.config.behaviors.clear()
	var ctx := SpellCastContext.new(actor,spell(4))
	check(SpellDelivery.can_target(ctx,node), "Neutral destructible is accepted by the production environmental target adapter")
	check(SpellDelivery.dispatch(ctx) == false, "Direct delivery still requires an explicitly selected target")
	ctx.targets = [node]
	check(SpellDelivery.dispatch(ctx) and component(node).health == 16, "Actual direct spell delivery damages destructible durability")
	ctx.spell.environmental_damage_kind = EnvironmentalDamage.Kind.THERMAL
	ctx.spell.spell_name = "No thermal word required"
	SpellExecutor.new().execute(ctx,node)
	check(is_equal_approx(component(node).health,8.8), "DamageEffect forwards explicit classification through the hitbox adapter")
	var player_node := load("res://components/characters/player/player.tscn").instantiate() as Player
	world.add_child(player_node); player_node.set_physics_process(false)
	var hp: float = Player_Global_Data.p_curr_health
	var direct := SpellCastContext.new(actor,spell(3))
	SpellExecutor.new().execute(direct,player_node)
	check(Player_Global_Data.p_curr_health == hp - 3, "Ordinary player DamageEffect behavior remains unchanged")
	var enemy := load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate() as Enemy
	enemy.position = Vector2(1500,0); world.add_child(enemy); enemy.set_physics_process(false)
	var before := enemy.current_health
	SpellExecutor.new().execute(SpellCastContext.new(actor,spell(5)),enemy)
	check(enemy.current_health == before - 5, "Existing Enemy V2 stats consume the same real hitbox damage")
	var deaths := [0]; enemy.enemy_died.connect(func(): deaths[0] += 1)
	var xp := Player_Global_Data.player_exp
	enemy.hitbox.receive_damage(100000,actor); enemy.hitbox.receive_damage(100000,actor)
	check(deaths[0] == 1 and Player_Global_Data.player_exp == xp + enemy.definition.experience_reward, "Enemy V2 death and XP resolve once through normal pipeline")
	await frames()
	var area_node := prop("glass-barrier",Vector2(100,0))
	var aoe := spell(3); aoe.delivery = SpellData.Delivery.AREA_BURST; aoe.aoe_spell_radius = 200
	check(SpellDelivery.apply_area(SpellCastContext.new(actor,aoe),Vector2(100,0)) and component(area_node).health < 8, "Production area delivery discovers destructibles via hitbox group")
	var beam := spell(2); beam.delivery = SpellData.Delivery.BEAM; beam.target_range = 300; beam.beam_width = 20
	var beam_ctx := SpellCastContext.new(actor,beam); beam_ctx.source_position = Vector2(-100,0)
	var delivery := SpellAreaDelivery.new(); delivery.context = beam_ctx; world.add_child(delivery); delivery.position = Vector2(-100,0); delivery.set_physics_process(false)
	check(delivery.cast_beams(), "Production beam delivery hits the destructible collision bounds")
	var remote := OfflineMultiplayerPeer.new()
	check(SpellExecutor.is_authoritative(node), "Single-player authority accepts local destructibles")
	check(remote != null, "Authority tests use the production guard rather than custom owner flags")
func destruction_context(node: DestructibleObject, behaviors: Array[DestructionBehavior]) -> DestructionContext:
	node.config.behaviors = behaviors
	var damage := EnvironmentalDamage.new(); damage.instigator = source()
	component(node).destroy(damage)
	return component(node)._context
func explosions() -> void:
	await isolate()
	var node := prop("explosive-barrel")
	var target := prop("wooden-crate",Vector2(100,0)); target.config.behaviors.clear()
	var outside := prop("wooden-crate",Vector2(700,0)); outside.config.behaviors.clear()
	var behavior := AreaExplosionBehavior.new(); behavior.base_damage = 10; behavior.explosion_radius = 200
	behavior.targets.require_line_of_sight = false
	destruction_context(node,[behavior])
	await wait(0.15)
	check(component(target).health < 20 and component(target).health > 10, "Explosion applies radial damage falloff")
	check(component(outside).health == 20, "Explosion never damages targets outside its radius")
	var effect := node.get_parent().get_node("DestructionRuntime").get_children().filter(func(n): return n is DestructionExplosion)[0] as DestructionExplosion
	var hp := component(target).health; effect.detonate()
	check(component(target).health == hp, "Explosion detonation is idempotent")
	await isolate()
	node = prop("explosive-barrel")
	target = prop("wooden-crate",Vector2(100,0)); target.config.behaviors.clear()
	behavior = AreaExplosionBehavior.new(); behavior.delay_seconds = 0.2; behavior.targets.require_line_of_sight = false
	destruction_context(node,[behavior])
	await wait(0.08)
	check(component(target).health == 20, "Delayed fuse does not explode early")
	await wait(0.3)
	check(component(target).is_destroyed(), "Delayed fuse eventually delivers real damage")
	var bad := AreaExplosionBehavior.new(); bad.explosion_radius = -1
	check(not bad.validate().is_empty(), "Invalid negative explosion radius is rejected")
	await isolate()
	node = prop("explosive-barrel"); target = prop("wooden-crate",Vector2(200,0)); target.config.behaviors.clear()
	var wall := StaticBody2D.new(); wall.collision_layer = 16; wall.position = Vector2(100,0)
	var collider := CollisionShape2D.new(); var rect := RectangleShape2D.new(); rect.size = Vector2(20,200); collider.shape = rect; wall.add_child(collider); world.add_child(wall)
	await frames()
	behavior = AreaExplosionBehavior.new(); behavior.explosion_radius = 400
	destruction_context(node,[behavior]); await wait(0.15)
	check(component(target).health == 20, "Explosion line of sight respects intervening terrain")
func hazards_and_shrapnel() -> void:
	await isolate()
	var node := prop("fragmentation-container")
	var definition := ShrapnelBehavior.new(); definition.direction_mode = ShrapnelBehavior.DirectionMode.RANDOMIZED; definition.seed_override = 12
	check(definition.directions(1) == definition.directions(2), "Shrapnel spread is deterministic with an authored seed")
	definition.direction_mode = ShrapnelBehavior.DirectionMode.UPWARD_BURST
	check(definition.directions(1).all(func(v): return v.y < 0), "Upward burst directs all fragments upward")
	definition.projectile_lifetime = 0.2
	destruction_context(node,[definition]); await wait(0.08)
	check(get_tree().get_nodes_in_group("destruction_shrapnel").size() == 12, "Shrapnel behavior spawns real bounded projectile nodes")
	await wait(0.3)
	check(get_tree().get_nodes_in_group("destruction_shrapnel").is_empty(), "Shrapnel expires and cleans up")
	definition.projectile_count = 1000
	check(not definition.validate().is_empty(), "Unsafe projectile counts are rejected")
	await isolate()
	node = prop("poison-canister")
	var target := prop("stone-block",Vector2(100,0))
	var hazard := PersistentHazardBehavior.new(); hazard.radius = 200; hazard.duration = 0.35; hazard.tick_interval = 0.1; hazard.damage_per_tick = 3; hazard.fade_out_duration = 0.1
	hazard.targets.require_line_of_sight = false
	var status := ApplyStatusEffect.new(); status.status = "slow"; status.duration = 0.25; status.magnitude = 0.4
	hazard.status_effect = status
	destruction_context(node,[hazard]); await wait(0.2)
	var clouds := get_tree().get_nodes_in_group("destruction_hazard")
	check(clouds.size() == 1 and component(target).health < 150, "Temporary cloud applies real periodic damage")
	var hitbox := target.get_node("HitboxComponent") as HitboxComponent
	check(hitbox.effects.get_entries().size() == 1 and hitbox.get_slow_factor() == 0.4, "Repeated cloud ticks refresh one supported status instead of stacking")
	await wait(0.45)
	check(get_tree().get_nodes_in_group("destruction_hazard").is_empty(), "Hazard duration and fade are bounded")
	await wait(0.3)
	check(not hitbox.effects.has("slow"), "Applied status expires through ActiveEffectManager")
	status.status = "not_implemented"
	check(not hazard.validate().is_empty(), "Unsupported status cannot be exposed as a working hazard")
	status.status = "slow"; status.stacking = ActiveEffectManager.StackPolicy.STACK
	check(not hazard.validate().is_empty(), "Unbounded hazard status stacking is rejected")
func spawning_and_events() -> void:
	await isolate()
	var node := prop("minion-pod")
	var spawn := node.config.behaviors[0] as SpawnActorBehavior
	spawn.delay_seconds = 0; spawn.lifetime = 2
	destruction_context(node,[spawn]); await wait(0.12)
	var actors := get_tree().get_nodes_in_group("destruction_actor")
	check(actors.size() == 3 and actors.all(func(actor): return actor is Enemy and actor.definition.enemy_id != ""), "Pod spawns three real Resource-driven Enemy V2 actors")
	check(actors.all(func(actor): return CombatFactions.faction(actor) == &"enemy" and actor.current_health > 0), "Minions preserve configured faction and enemy stats")
	spawn.spawn_count = -1
	check(not spawn.validate().is_empty(), "Invalid actor counts fail validation")
	var missing := SpawnSceneBehavior.new()
	check(not missing.validate().is_empty(), "Missing PackedScene fails validation")
	await isolate()
	node = prop()
	var first := SignalEventBehavior.new(); first.event_id = &"first"; first.delay_seconds = 0.1
	var second := SignalEventBehavior.new(); second.event_id = &"second"; second.action = SignalEventBehavior.Action.WORLD_FLAG; second.world_flag = "destruction_test_story"
	var events: Array[StringName] = []
	component(node).authored_event.connect(func(id,_ctx): events.append(id))
	destruction_context(node,[first,second]); await wait(0.06)
	check(events.is_empty(), "Behavior delay precedes ordered execution")
	await wait(0.2)
	check(events == [&"first",&"second"] and QuestManager.world_flags.get("destruction_test_story",false), "Combined behaviors execute in authored order and publish a real world flag")
	await isolate()
	node = prop()
	var loot := LootDropBehavior.new(); var entry := load("res://data/loot/enemy-drops/test-loot1.tres").duplicate() as LootData; entry.drop_chance = 1; loot.entries = [entry]; loot.scatter = 0
	var before := Inventory_Manager.get_item_quantity(entry.item.item_id)
	var ctx := destruction_context(node,[loot]); await wait(0.1)
	var drops: Array[Node] = []
	for ref in ctx.runtime.spawned:
		var drop: Node = ref.get_ref()
		if drop is DroppedItem: drops.append(drop)
	check(drops.size() == 1 and Inventory_Manager.get_item_quantity(entry.item.item_id) == before, "Destruction creates a physical drop without granting inventory prematurely")
	check(not component(node).destroy() and drops.size() == 1, "Repeated destruction cannot duplicate loot")
	var collector := source(); collector.add_to_group("player")
	var acquired: int = drops[0].pickup(collector)
	check(acquired == 1 and Inventory_Manager.get_item_quantity(entry.item.item_id) == before + 1, "Real pickup uses inventory receipt and acquisition validation")
func chains_and_limits() -> void:
	await isolate()
	var barrels: Array[DestructibleObject] = []
	for index in 12:
		var node := prop("explosive-barrel",Vector2(index * 85,0))
		var behavior := node.config.behaviors[0] as AreaExplosionBehavior
		behavior.base_damage = 100; behavior.explosion_radius = 125; behavior.targets.require_line_of_sight = false
		barrels.append(node)
	var first := destruction_context(barrels[0],barrels[0].config.behaviors)
	first.budget.max_depth = 16
	await wait(1.5)
	check(barrels.all(func(node): return component(node).is_destroyed()), "Twelve explosive barrels chain without recursive execution")
	check(first.budget.remaining_destructions == 20 and first.budget.remaining_spawns >= 0, "A shared chain budget counts every destruction once")
	await isolate()
	var a := prop("explosive-barrel"); var b := prop("explosive-barrel",Vector2(80,0)); var c := prop("explosive-barrel",Vector2(160,0))
	for barrel in [a,b,c]:
		var behavior := barrel.config.behaviors[0] as AreaExplosionBehavior
		behavior.targets.require_line_of_sight = false; behavior.base_damage = 100; behavior.explosion_radius = 110
	first = destruction_context(a,a.config.behaviors); first.budget.remaining_destructions = 0
	await wait(0.4)
	check(component(b).is_destroyed() and not component(c).is_destroyed(), "Budget exhaustion permits broken visuals but stops further propagation")
	await isolate()
	a = prop(); var delayed := AreaExplosionBehavior.new(); delayed.delay_seconds = 0.2
	destruction_context(a,[delayed]); a.queue_free(); await wait(0.35)
	check(get_tree().get_nodes_in_group("destruction_explosion").is_empty(), "Removing an owner cancels pending delayed behaviors")
func persistence() -> void:
	await isolate()
	var node := prop(); node.config.persistent = true; node.config.persistence_id = "framework_persistence"; node.config.behaviors.clear()
	component(node).set_health(7.25)
	var saved := DestructiblePersistence.restore(node.config)
	check(saved.health == 7.25 and not saved.destroyed, "Save V1 Boolean flags retain hundredth-point durability")
	var config := node.config.duplicate(true) as DestructibleConfig
	node.free()
	var restored := load(BASE + "destructible-object.tscn").instantiate() as DestructibleObject; restored.config = config; world.add_child(restored)
	check(component(restored).health == 7.25 and not component(restored).is_destroyed(), "Reinstancing restores partial damage state")
	component(restored).destroy(); restored.free()
	await frames()
	restored = load(BASE + "destructible-object.tscn").instantiate() as DestructibleObject; restored.config = config; world.add_child(restored)
	check(component(restored).is_destroyed() and component(restored).effects_executed and component(restored).runtime.jobs.is_empty(), "Loading a destroyed object never replays behaviors or loot")
	config.respawn_on_scene_reload = true
	var fresh := load(BASE + "destructible-object.tscn").instantiate() as DestructibleObject; fresh.config = config; world.add_child(fresh)
	check(not component(fresh).is_destroyed() and component(fresh).health == config.max_health, "Explicit respawn-on-reload ignores destruction flags")

func edge_cases() -> void:
	await isolate()
	var node := prop(); var c := component(node)
	var client := ENetMultiplayerPeer.new()
	check(client.create_client("127.0.0.1",19994) == OK, "Authority test creates a real client peer")
	multiplayer.multiplayer_peer = client
	check(not c.apply_damage(100) and not c.destroy() and not c.reset_destructible(), "Multiplayer clients cannot mutate destructible durability or execute behaviors")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new(); client.close()
	var replacement := SpawnSceneBehavior.new(); replacement.scene = load(BASE+"presets/glass-barrier.tscn"); replacement.lifetime = 0.2
	var ctx := destruction_context(node,[replacement]); await wait(0.1)
	var replacements: Array[Node] = []
	for ref in ctx.runtime.spawned:
		if ref.get_ref() is DestructibleObject: replacements.append(ref.get_ref())
	check(replacements.size() == 1 and replacements[0].has_meta("destruction_parent_context"), "Scene spawning creates a real destructible with inherited propagation ownership")
	await wait(0.25)
	check(not is_instance_valid(replacements[0]), "Spawned replacement lifetime is bounded")
	await isolate()
	node = prop("fragmentation-container")
	var target := prop("wooden-crate",Vector2(95,0)); target.config.behaviors.clear()
	var fragments := ShrapnelBehavior.new(); fragments.direction_mode = ShrapnelBehavior.DirectionMode.CONE; fragments.projectile_count = 1; fragments.projectile_damage = 8; fragments.gravity_enabled = false; fragments.projectile_speed = 800
	destruction_context(node,[fragments]); await wait(0.2)
	check(component(target).health == 12, "Swept physical shrapnel collision applies real damage without tunneling")
	await isolate()
	node = prop("poison-canister"); target = prop("stone-block",Vector2(100,0))
	var cloud := PersistentHazardBehavior.new(); cloud.damage_per_tick = 0; cloud.duration = 0.4; cloud.tick_interval = 0.05; cloud.targets.require_line_of_sight = false; cloud.reentry_policy = PersistentHazardBehavior.ReentryPolicy.ONCE_PER_ACTOR
	var status := ApplyStatusEffect.new(); status.status = "slow"; status.duration = 0.1; status.magnitude = 0.3; cloud.status_effect = status
	destruction_context(node,[cloud]); await wait(0.3)
	check(component(target).health == 150 and not (target.get_node("HitboxComponent") as HitboxComponent).effects.has("slow"), "Once-per-actor hazard never refreshes expired status or deals unconfigured damage")
	await isolate()
	node = prop(); target = prop("wooden-crate",Vector2(80,0))
	var explosion := AreaExplosionBehavior.new(); explosion.chain_reaction_enabled = false; explosion.targets.require_line_of_sight = false
	destruction_context(node,[explosion]); await wait(0.1)
	check(component(target).health == 20, "Disabling environmental chain reactions leaves nearby destructibles intact")
	await isolate()
	node = prop("minion-pod")
	var actors := node.config.behaviors[0] as SpawnActorBehavior; actors.delay_seconds = 0; actors.spawn_pattern = SpawnActorBehavior.Pattern.ORIGIN; actors.placement_attempts = 1
	var wall := StaticBody2D.new(); wall.collision_layer = 16
	var collision := CollisionShape2D.new(); var rectangle := RectangleShape2D.new(); rectangle.size = Vector2(800,800); collision.shape = rectangle; wall.add_child(collision); world.add_child(wall)
	await frames()
	destruction_context(node,[actors]); await wait(0.1)
	check(get_tree().get_nodes_in_group("destruction_actor").is_empty(), "Actor placement rejects a spawn fully enclosed by solid terrain")
	await isolate()
	node = prop("explosive-barrel")
	explosion = AreaExplosionBehavior.new(); explosion.delay_seconds = 0.2
	destruction_context(node,[explosion])
	world.free(); world = Node2D.new(); add_child(world)
	await wait(0.3)
	check(get_tree().get_nodes_in_group("destruction_explosion").is_empty(), "Scene unload removes pending effects and their scheduler")

func additional_coverage() -> void:
	await isolate()
	var node := prop(); var c := component(node); node.config.behaviors.clear()
	var transitions := [0]
	c.state_changed.connect(func(_previous,_current): transitions[0] += 1)
	c.apply_damage(1); c.apply_damage(1)
	check(transitions[0] == 0, "Repeated damage inside one threshold does not replay a state transition")
	for kind in EnvironmentalDamage.Kind.size():
		c.reset_destructible(); node.config.material = DestructibleMaterialDefinition.new()
		var property: String = ["impact_multiplier","thermal_multiplier","electrical_multiplier","pressure_multiplier","sonic_multiplier"][kind]
		node.config.material.set(property,2.0)
		var damage := EnvironmentalDamage.new(); damage.kind = kind
		check(c.apply_damage(2,damage) and c.health == 16, "Material classification applies exact authored response: "+property)
	var invalid_config := node.config.duplicate(true) as DestructibleConfig
	invalid_config.states.remove_at(0)
	check(not invalid_config.validate().is_empty(), "Missing intact threshold is diagnosed")
	var invalid_damage := EnvironmentalDamage.new(); invalid_damage.kind = -1
	check(not c.apply_damage(2,invalid_damage), "Invalid typed damage classification is rejected safely")
	var delayed := SignalEventBehavior.new(); delayed.delay_seconds = 0.2
	var events := [0]; c.authored_event.connect(func(_id,_ctx): events[0] += 1)
	destruction_context(node,[delayed]); c.reset_destructible(); await wait(0.3)
	check(events[0] == 0 and not c.is_destroyed(), "Reset invalidates the prior generation's pending effects")
	var bad := AreaExplosionBehavior.new(); bad.explosion_radius = -10
	var final := SignalEventBehavior.new()
	destruction_context(node,[bad,final]); await wait(0.1)
	check(events[0] == 1 and c.effects_executed, "An invalid optional behavior is skipped and ordered lifecycle still finishes")
	await isolate()
	node = prop(); var reactor: Array[DestructionBehavior] = []
	var blast := AreaExplosionBehavior.new(); blast.base_damage = 0
	var fragments := ShrapnelBehavior.new(); fragments.gravity_enabled = false
	var cloud := PersistentHazardBehavior.new(); cloud.damage_per_tick = 0
	var spawn := (load(BASE+"presets/minion-pod.tres") as DestructibleConfig).behaviors[0].duplicate(true) as SpawnActorBehavior
	spawn.delay_seconds = 0; spawn.spawn_count = 3; spawn.max_active_spawned_actors = 1
	reactor = [blast,fragments,cloud,spawn]
	destruction_context(node,reactor); await wait(0.2)
	check(get_tree().get_nodes_in_group("destruction_explosion").size() == 1 and get_tree().get_nodes_in_group("destruction_shrapnel").size() == 12 and get_tree().get_nodes_in_group("destruction_hazard").size() == 1, "One reactor composes explosion, fragments and a persistent field")
	check(get_tree().get_nodes_in_group("destruction_actor").size() == 1, "Combined actor behavior enforces its configured active cap")
	await isolate()
	node = prop("fragmentation-container")
	var a := prop("wooden-crate",Vector2(90,0)); var b := prop("wooden-crate",Vector2(170,0))
	a.config.behaviors.clear(); b.config.behaviors.clear()
	fragments = ShrapnelBehavior.new(); fragments.projectile_count = 1; fragments.direction_mode = ShrapnelBehavior.DirectionMode.CONE; fragments.piercing_enabled = true; fragments.max_pierces = 2; fragments.projectile_speed = 1200; fragments.gravity_enabled = false
	destruction_context(node,[fragments]); await wait(0.25)
	check(component(a).health == 12 and component(b).health == 12, "Piercing shrapnel hits two distinct bodies once each")
	await isolate()
	node = prop()
	var actor := load("res://components/characters/player/player.tscn").instantiate() as Player
	actor.position = Vector2(70,0); world.add_child(actor); actor.set_physics_process(false)
	Player_Global_Data.p_curr_health = Player_Global_Data.p_max_health
	var enemy := load("res://components/NPCs/enemies/zalam-manifestations/bunga/bunga.tscn").instantiate() as Enemy
	enemy.position = Vector2(150,0); world.add_child(enemy); enemy.set_physics_process(false)
	var hp := enemy.current_health; var player_hp := Player_Global_Data.p_curr_health
	var impulses := [0]; enemy.hitbox.knocked_back.connect(func(_force): impulses[0] += 1)
	blast = AreaExplosionBehavior.new(); blast.base_damage = 5; blast.targets.require_line_of_sight = false
	var damage := EnvironmentalDamage.new(); damage.instigator = actor
	node.config.behaviors = [blast]; component(node).destroy(damage)
	await wait(0.12)
	check(enemy.current_health < hp and impulses[0] == 1 and enemy.get_node_or_null("SpellMotionImpulse") != null, "Explosion damages and knocks back real Enemy V2 through the existing hitbox")
	check(Player_Global_Data.p_curr_health == player_hp, "Default faction policy protects the player who triggered the explosion")
	await isolate()
	var first := load(BASE+"presets/wooden-crate.tscn").instantiate() as DestructibleObject
	first.config = first.config.duplicate(true); first.config.persistent = true; first.config.persistence_id = "duplicate_test"; world.add_child(first)
	var duplicate := load(BASE+"presets/wooden-crate.tscn").instantiate() as DestructibleObject
	duplicate.config = first.config; world.add_child(duplicate)
	check(not component(duplicate)._persistence_allowed, "Duplicate placed persistence IDs cannot overwrite the first object's flags")

	await isolate()
	node = prop(); c = component(node)
	final = SignalEventBehavior.new(); final.action = SignalEventBehavior.Action.WORLD_FLAG; final.world_flag = "removed_signal_owner"
	c.authored_event.connect(func(_id,_ctx): node.queue_free())
	destruction_context(node,[final]); await wait(0.1)
	check(not QuestManager.world_flags.get("removed_signal_owner",false), "An authored event can remove its owner without executing stale target actions")
