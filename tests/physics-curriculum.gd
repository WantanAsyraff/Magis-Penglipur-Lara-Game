extends Node
const Actor = preload("res://tests/spell-regression.gd").TestActor
const COURSE = preload("res://data/magis/ilmiah/physics-field/physical-science.tres")
var completed: bool = false
var checks := 0
var failures := 0
var sandbox: Node2D
var caster: CharacterBody2D
var target: CharacterBody2D
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func definition(slug: String) -> SpellData:
	return load("res://data/magis/spells/" + slug + ".tres")
func actor(at: Vector2, player_team: bool = false) -> CharacterBody2D:
	var a := Actor.new()
	if player_team: a.add_to_group("player")
	sandbox.add_child(a)
	a.position = at
	a.mana = 10000
	a.health = 10000
	a.set_meta("structural", true)
	a.set_meta("magnetic", true)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 10
	a.add_child(shape)
	a.collision_layer = 1 if player_team else 2
	a.collision_mask = 16
	return a
func context(slug: String, victim: Node2D = null) -> SpellCastContext:
	if victim == null: victim = target
	var c := SpellCastContext.new(caster, definition(slug))
	c.direction = Vector2.RIGHT
	c.source_position = Vector2.ZERO
	if victim: c.targets = [victim]
	return c
func payload(slug: String, victim: Node2D = null) -> bool:
	if victim == null: victim = target
	return SpellExecutor.new().execute(context(slug, victim), victim)
func _ready() -> void:
	await get_tree().process_frame
	await run()
	check(completed, "Curriculum suite reached its final assertion")
	print("PHYSICS_CURRICULUM: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func reset() -> void:
	if is_instance_valid(sandbox):
		sandbox.free()
	sandbox = Node2D.new()
	add_child(sandbox)
	caster = actor(Vector2.ZERO, true)
	target = actor(Vector2(100, 0))
func run() -> void:
	reset()
	check(COURSE.subjects.size() == 12 and AcademicValidator.validate_course(COURSE).is_empty(), "12 subjects form a valid prerequisite DAG")
	var ids := {}
	var sequences := {}
	var total := 0
	for subject in COURSE.subjects:
		for spell in subject.contained_spells:
			total += 1
			check(not ids.has(spell.spell_id) and SpellValidator.validate(spell).is_empty(), "unique valid resource: " + spell.spell_name)
			ids[spell.spell_id] = true
			var key := ",".join(spell.spell_incantation)
			check(not sequences.has(key), "unique incantation: " + spell.spell_name)
			sequences[key] = true
			var resolver := IncantationResolver.new()
			resolver.strategy = IncantationResolver.Strategy.CONFIRMATION
			var repertoire: Array[SpellData] = []
			repertoire.assign(Spell_Library.all_spells.values())
			resolver.rebuild(repertoire)
			var early := false
			for step in spell.spell_incantation:
				if resolver.push(step): early = true
			check(not early and resolver.confirm() == spell, "confirmation resolves without prefix casts: " + spell.spell_name)
	check(total == 42 and ids.size() == 42, "42 spells are connected once each")
	for file in ["phys-force", "phys-strike", "phys-crash", "phys-resonate", "phys-shatterwave", "phys-collapse", "phys-terminal", "thermal-kinetic"]:
		check(definition(file) != null, "legacy path retained: " + file)
	# Cast every authored resource through production validation, costs and delivery.
	for subject in COURSE.subjects:
		for spell in subject.contained_spells:
			reset()
			var h: HitboxComponent = target.get_node("HitboxComponent")
			h.effects.apply("resonance", 5, {"amount": 1})
			h.effects.apply("brittle", 5, {})
			h.effects.apply("cooled", 5, {})
			h.effects.apply("heated", 5, {})
			caster.casting.previous_spell = definition("phys-force")
			var cast_targets: Array[Node2D] = [target]
			var accepted: bool = caster.casting.request_cast(spell, Vector2.ZERO, Vector2.RIGHT, cast_targets)
			caster.casting._physics_process(spell.cast_time + .01)
			if spell.is_channelled:
				for child in sandbox.get_children():
					if child is SpellAreaDelivery: child._physics_process(.01)
				caster.casting._physics_process(spell.channel_duration)
			var delivered: bool = accepted and caster.mana < 10000 and caster.casting.cooldowns.has(spell.spell_id)
			for child in sandbox.get_children():
				if child is MagicProjectile:
					child._on_body_entered(target)
				if child is SpellAreaDelivery and not child.is_queued_for_deletion():
					child._physics_process(.01)
				if child is SpellConstruct:
					child._physics_process(.01)
			check(delivered, "production cast completes and spends mana: " + spell.spell_name)
	# Status interactions use actual authored effect arrays.
	reset()
	payload("phys-resonate")
	payload("phys-resonate")
	check(target.hitbox.effects.entries.filter(func(e): return e.key == "resonance").size() == 2, "Resonate independently stacks")
	var before: float = target.total_damage
	payload("phys-shatterwave")
	check(target.total_damage == before + 37 and not target.hitbox.effects.has("resonance"), "Resonate -> Shatterwave consumes status and amplifies")
	payload("thermal-kinetic")
	before = target.total_damage
	payload("phys-thermal-bloom")
	check(target.total_damage == before + 17 and not target.hitbox.effects.has("cooled") and not target.hitbox.effects.has("slow"), "Chill -> Bloom thermal shock consumes cooling")
	payload("phys-brittle-fracture")
	before = target.total_damage
	payload("phys-crash")
	check(target.total_damage == before + 50 and target.hitbox.is_stunned(), "Brittle -> Crash structural amplification")
	reset()
	payload("phys-magnetic-tether")
	check(target.hitbox.effects.has("charged") and target.velocity.x < 0, "Tether charges and attracts explicitly magnetic target")
	for i in 5: actor(Vector2(120 + i * 20, 0))
	before = target.total_damage
	payload("phys-static-arc")
	var chained := 0
	for a in sandbox.get_children():
		if a is Actor and a != target and a != caster and a.total_damage > 0: chained += 1
	check(target.total_damage == before + 20 and chained == 3, "Static Arc charged bonus and exactly three additional targets")
	reset()
	target.remove_meta("magnetic")
	payload("phys-magnetic-tether")
	check(target.velocity == Vector2.ZERO and target.hitbox.effects.has("charged"), "Nonmagnetic target receives magical charge without attraction")
	payload("phys-resonance-threshold")
	payload("phys-resonate")
	var hit := DamageEffect.new()
	hit.amount = 1
	SpellExecutor.execute_effects(context("phys-force"), target, [hit])
	before = target.total_damage
	SpellExecutor.execute_effects(context("phys-force"), target, [hit])
	check(target.total_damage == before + 36 and not target.hitbox.effects.has("resonance"), "Threshold fires once on third impact")
	SpellExecutor.execute_effects(context("phys-force"), target, [hit])
	check(target.total_damage == before + 37, "Threshold does not recursively repeat")
	payload("phys-impact-prism", caster)
	SpellExecutor.execute_effects(context("phys-force"), caster, [damage_for_test(20)])
	check(caster.hitbox.effects.has("buff_damage"), "Impact Prism reacts to a damaging hit")
	# Local projectile manipulation and ownership.
	reset()
	var hostile := SpellCastContext.new(target, definition("phys-force"))
	hostile.source_position = Vector2(50, 0)
	hostile.direction = Vector2.LEFT
	SpellDelivery.dispatch(hostile)
	var projectile := sandbox.get_children().back() as MagicProjectile
	SpellDelivery.dispatch(context("phys-vector-reversal"))
	check(projectile.direction == Vector2.RIGHT and projectile.source == caster and projectile.collision_mask == 18, "Reversal transfers heading, owner and collision mask")
	before = target.total_damage
	projectile._on_body_entered(target)
	check(target.total_damage > before, "Reversed projectile damages original team")
	SpellDelivery.dispatch(hostile)
	projectile = sandbox.get_children().back() as MagicProjectile
	projectile.global_position = Vector2(50, 50)
	var original := projectile.direction
	var lens := context("phys-gravitational-lens")
	SpellDelivery.apply_area(lens, Vector2.ZERO)
	check(projectile.direction != original, "Lens changes projectile trajectory")
	var dilation := context("phys-time-dilation-zone")
	SpellDelivery.apply_area(dilation, Vector2.ZERO)
	check(projectile.local_speed_factor == .35 and target.hitbox.get_slow_factor() == .6 and Engine.time_scale == 1, "Dilation locally slows actors and projectiles")
	projectile._physics_process(.4)
	check(projectile.local_speed_factor == 1, "Projectile speed recovers outside dilation")
	# Pure projectile bursts work without an enemy in the area.
	reset()
	var wave := definition("phys-resonate")
	SpellDelivery.dispatch(SpellCastContext.new(target, wave))
	projectile = sandbox.get_children().back() as MagicProjectile
	projectile.global_position = Vector2(30, 0)
	SpellDelivery.dispatch(context("phys-phase-cancellation"))
	check(projectile.is_queued_for_deletion(), "Phase Cancellation cancels eligible wave projectile")
	# Healing / cleanses and timed stats.
	caster.hitbox.effects.apply("resonance", 5, {})
	caster.hitbox.effects.apply("slow", 5, {"factor": .5})
	var hp: float = caster.health
	payload("phys-harmonic-stabilization", caster)
	check(caster.health == hp + 22 and not caster.hitbox.effects.has("slow") and not caster.hitbox.effects.has("resonance"), "Harmonic healing and selected status removal")
	payload("phys-heat-engine", caster)
	check(caster.hitbox.effects.magnitude("buff_mana_regen") == 4, "Heat Engine grants reusable stat buffs")
	caster.hitbox.effects.tick(6)
	check(caster.hitbox.effects.magnitude("buff_mana_regen") == 0, "Stat buffs expire")
	# Live channel runs before completion and stops on interruption.
	reset()
	var jet := definition("phys-pressure-jet")
	caster.casting.request_cast(jet, Vector2.ZERO, Vector2.RIGHT)
	caster.casting._physics_process(jet.cast_time)
	var area: SpellAreaDelivery = caster.casting.live_delivery
	area._physics_process(.01)
	check(target.velocity.x > 0 and caster.casting.state == SpellCastingComponent.State.CHANNELING, "Pressure Jet emits force during channel")
	var paid: float = caster.mana
	caster.casting._physics_process(.5)
	check(caster.mana == paid - 2.5, "Live channel charges elapsed mana")
	payload("phys-sonic-pulse", caster)
	check(caster.casting.state == SpellCastingComponent.State.IDLE and area.is_queued_for_deletion() and caster.mana == paid - 2.5, "Sonic Pulse interrupts channel without refunding delivered payload")
	# Echo cannot replace its own previous eligible payload or recurse.
	reset()
	caster.casting.request_cast(definition("phys-force"), Vector2.ZERO, Vector2.RIGHT)
	caster.casting._physics_process(definition("phys-force").cast_time)
	var previous: SpellData = caster.casting.previous_spell
	var echo := definition("phys-probabilistic-echo")
	caster.casting.request_cast(echo, Vector2.ZERO, Vector2.RIGHT)
	caster.casting._physics_process(echo.cast_time)
	projectile = sandbox.get_children().back() as MagicProjectile
	before = target.total_damage
	projectile._on_body_entered(target)
	check(target.total_damage == before + 8.5 and caster.casting.previous_spell == previous, "Echo repeats half-damage Force once and preserves eligible history")
	reset()
	paid = caster.mana
	caster.casting.request_cast(echo, Vector2.ZERO, Vector2.RIGHT)
	caster.casting._physics_process(echo.cast_time)
	check(caster.mana == paid, "Echo without history fails safely and refunds")
	# Areas and constructs have lifetimes; traps trigger once.
	reset()
	for slug in ["phys-thermal-bloom", "phys-induction-grid", "phys-decoherence-trap"]:
		var c := context(slug)
		SpellDelivery.dispatch(c)
		area = sandbox.get_children().back() as SpellAreaDelivery
		before = target.total_damage
		area._physics_process(.01)
		check(target.total_damage > before, "Area/trap actually executes: " + slug)
		area._physics_process(c.spell.area_duration + 1)
		check(area.is_queued_for_deletion(), "Area/trap cleanup: " + slug)
	for slug in ["phys-gyroscopic-shield", "phys-faraday-cage", "phys-elastic-barrier", "phys-structural-fabrication", "phys-total-internal-reflection"]:
		var c := context(slug)
		SpellDelivery.dispatch(c)
		var construct := sandbox.get_children().back() as SpellConstruct
		check(construct != null and (not c.spell.construct_solid or construct.get_child_count() > 0), "Construct has configured geometry: " + slug)
		construct._physics_process(c.spell.area_duration + 1)
		check(construct.is_queued_for_deletion(), "Construct expires: " + slug)
	# Collision-tested teleport and optical interfaces.
	reset()
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 200)
	shape.shape = rect
	wall.add_child(shape)
	sandbox.add_child(wall)
	wall.position = Vector2(60, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not payload("phys-tunneling-step", caster) and caster.position == Vector2.ZERO, "Teleport rejects obstructed swept path")
	var beam_context := context("phys-refraction-beam")
	SpellDelivery.dispatch(beam_context)
	area = sandbox.get_children().back() as SpellAreaDelivery
	before = target.total_damage
	area._physics_process(.01)
	check(target.total_damage == before and area.beam_segments.size() == 2, "Terrain occludes beam damage")
	wall.set_meta("optical_interface", 90.0)
	area.until_tick = 0
	area._physics_process(.01)
	check(area.beam_segments.size() == 4 and area.beam_segments[3].y > 100, "Configured optical interface turns beam")
	wall.remove_meta("optical_interface")
	wall.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(payload("phys-tunneling-step", caster) and caster.position.x == 160, "Teleport succeeds in open space")
	caster.position = Vector2.ZERO
	SpellDelivery.dispatch(context("phys-prism-split"))
	area = sandbox.get_children().back() as SpellAreaDelivery
	area._physics_process(.01)
	check(area.beam_segments.size() == 6, "Prism Split emits three bounded paths")
	var invalid := context("phys-momentum-anchor")
	invalid.targets.clear()
	check(not SpellDelivery.dispatch(invalid), "Direct target fails safely without target")
	var isolated := context("phys-force")
	isolated.state.visited = true
	check(not context("phys-force").state.has("visited"), "Cast state remains isolated")
	# Shared mechanics also produce physical outcomes in the scene tree.
	reset()
	var start := caster.position
	payload("phys-inertia-vault", caster)
	var motion := caster.get_node("SpellMotionImpulse") as SpellMotionImpulse
	motion._physics_process(.05)
	check(caster.position.x > start.x, "Inertia Vault physically traverses despite controller velocity replacement")
	payload("phys-gravitational-well")
	before = target.total_damage
	payload("phys-thermal-bloom")
	check(target.velocity.x < 0 and target.total_damage > before, "Gravity grouping and thermal zone compose without combined spell code")
	reset()
	SpellDelivery.dispatch(context("phys-gyroscopic-shield"))
	var shield := sandbox.get_children().back() as SpellConstruct
	var shot := SpellCastContext.new(target, definition("phys-force"))
	shot.source_position = Vector2(30, 0)
	shot.direction = Vector2.LEFT
	SpellDelivery.dispatch(shot)
	projectile = sandbox.get_children().back() as MagicProjectile
	shield._physics_process(.01)
	check(projectile.is_queued_for_deletion(), "Gyroscopic construct physically intercepts hostile projectile")
	reset()
	var platform_context := context("phys-structural-fabrication")
	platform_context.source_position = Vector2(0, 50)
	SpellDelivery.dispatch(platform_context)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(caster.test_move(caster.global_transform, Vector2(0, 100)), "Fabricated platform blocks body motion")
	check(not SpellDelivery.dispatch(platform_context), "Overlapping solid construct is rejected")
	reset()
	var mirror_context := context("phys-total-internal-reflection")
	mirror_context.source_position = Vector2(0, -50)
	SpellDelivery.dispatch(mirror_context)
	target.position = Vector2(0, -100)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var enemy_beam := SpellCastContext.new(target, definition("phys-refraction-beam"))
	enemy_beam.source_position = target.global_position
	enemy_beam.direction = Vector2.DOWN
	SpellDelivery.dispatch(enemy_beam)
	area = sandbox.get_children().back() as SpellAreaDelivery
	before = target.total_damage
	area._physics_process(.01)
	check(target.total_damage > before and caster.total_damage == 0, "Optical shield returns beam with defending team ownership")
	# Native subject completion gates the expanded graph and charges each once.
	var saved_subjects: Array[String] = Player_Global_Data.completed_subjects.duplicate()
	var saved_spells: Array[SpellData] = Player_Global_Data.learned_spells.duplicate()
	var saved_xp: int = Player_Global_Data.player_exp
	Player_Global_Data.completed_subjects.clear()
	Player_Global_Data.player_exp = 100000
	for subject in COURSE.subjects:
		check(Player_Global_Data.call("purchase_subject", subject, COURSE), "Progression purchases " + subject.subject_id)
		var after: int = Player_Global_Data.player_exp
		check(not Player_Global_Data.call("purchase_subject", subject, COURSE) and Player_Global_Data.player_exp == after, "Completed subject never charges twice: " + subject.subject_id)
	check(Player_Global_Data.completed_subjects.size() == 12, "All twelve subjects have explicit completion")
	Player_Global_Data.completed_subjects = saved_subjects
	Player_Global_Data.learned_spells = saved_spells
	Player_Global_Data.player_exp = saved_xp
	reset()
	for i in 12: check(SpellDelivery.dispatch(context("phys-thermal-bloom")), "Persistent slot %d accepted" % i)
	check(not SpellDelivery.dispatch(context("phys-thermal-bloom")), "Thirteenth persistent node rejected")
	var bad_live := definition("phys-inertia-vault").duplicate() as SpellData
	bad_live.live_channel = true
	check(not SpellValidator.validate(bad_live).is_empty(), "Invalid live delivery configuration rejected")
	reset()
	var tree_view: SpellTreeView = load("res://scenes/spell-tree/spell-tree.tscn").instantiate()
	tree_view.course_data = COURSE
	sandbox.add_child(tree_view)
	await get_tree().process_frame
	await get_tree().process_frame
	check(tree_view.container.nodes_map.size() == 12 and tree_view.container.custom_minimum_size.x > 1000, "Production spell tree builds twelve nodes and scroll bounds")
	sandbox.free()
	completed = true
func damage_for_test(amount: float) -> DamageEffect:
	var effect := DamageEffect.new()
	effect.amount = amount
	return effect
