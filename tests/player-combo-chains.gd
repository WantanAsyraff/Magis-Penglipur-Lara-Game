extends Node
var checks := 0
var failures := 0
var casts: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func spell(id: String, combo: Array[String]) -> SpellData:
	var result := SpellData.new()
	result.spell_id = id
	result.spell_name = id
	result.spell_incantation = combo
	result.delivery = SpellData.Delivery.SELF
	result.upfront_cost = 2
	result.recovery_time = 0
	var heal := HealEffect.new()
	heal.amount = 1
	result.effects = [heal]
	return result
func _ready() -> void:
	await get_tree().process_frame
	check(Player_Global_Data.player_exp == 9999, "Player starts with 9999 XP")
	check(Player_Global_Data.p_max_health == 400 and Player_Global_Data.p_curr_health == 400, "Player starts at four times health, 400/400")
	var short := spell("test_short_combo", ["up", "down"])
	var longer := spell("test_long_combo", ["up", "down", "right"])
	var other := spell("test_next_combo", ["left", "up"])
	Player_Global_Data.learned_spells.assign([short, longer, other])
	Player_Global_Data.equipped_spells.assign([short, longer, other])
	Player_Global_Data.combat_mode = true
	Player_Global_Data.p_curr_health = 200
	var player: Player = load("res://components/characters/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.casting.set_physics_process(false)
	player.hitbox.set_physics_process(false)
	player.casting.cast_completed.connect(func(context): casts.append(context.spell.spell_id))
	check(player.incantation_strategy == IncantationResolver.Strategy.CHAINED, "Production player defaults to chained auto-casting")
	player._enter_casting_stance()
	player._add_sequence("up")
	check(casts.is_empty(), "An incomplete combo never casts")
	player._add_sequence("down")
	check(casts == [short.spell_id] and Player_Global_Data.p_curr_health == 201, "Final arrow triggers the production cast without confirmation")
	check(player.spell_string == ["up", "down"], "Completed prefix retains its longer-combo continuation")
	player._add_sequence("right")
	check(casts == [short.spell_id, longer.spell_id] and player.spell_string.is_empty(), "Longer combo also casts once when completed")
	player._add_sequence("left")
	player._add_sequence("up")
	check(casts.back() == other.spell_id and player._in_casting_stance, "Another full combo casts without closing stance")
	player._add_sequence("up")
	player._add_sequence("down")
	player._add_sequence("left")
	check(player.spell_string == ["left"], "An independent combo keeps its first arrow after a completed prefix")
	player._add_sequence("up")
	check(casts.back() == other.spell_id, "Independent follow-up combo completes normally")
	player.casting.cooldowns[short.spell_id] = 5.0
	var before := casts.size()
	player._add_sequence("up")
	player._add_sequence("down")
	check(casts.size() == before and player.spell_string == ["up", "down"], "Cooling-down prefix does not erase the path to a longer combo")
	player._add_sequence("right")
	check(casts.size() == before + 1 and casts.back() == longer.spell_id, "Available longer combo survives its prefix's cooldown rejection")
	player.casting.cooldowns.clear()
	short.cast_time = .4
	before = casts.size()
	var mana_before: float = Player_Global_Data.p_curr_mana
	for key in ["up", "down", "right", "left", "up"]: player._add_sequence(key)
	check(player.casting.state == SpellCastingComponent.State.PREPARING and player.casting._queue.size() == 2, "Fast completed combos queue while the first spell prepares")
	check(Player_Global_Data.p_curr_mana == mana_before - 2, "Pending combos do not precharge mana")
	player.casting._physics_process(.4)
	player.casting._physics_process(0)
	player.casting._physics_process(0)
	check(casts.slice(before) == [short.spell_id, longer.spell_id, other.spell_id], "Queued combo chain dispatches once each in input order")
	check(Player_Global_Data.p_curr_mana == mana_before - 6, "Each queued spell pays mana when it starts")
	# Queued spells are checked again when they actually start.
	before = casts.size()
	for key in ["up", "down", "right", "left", "up"]: player._add_sequence(key)
	Player_Global_Data.equipped_spells.erase(longer)
	Player_Global_Data.spells_updated.emit()
	player.casting._physics_process(.4)
	player.casting._physics_process(0)
	player.casting._physics_process(0)
	check(casts.slice(before) == [short.spell_id, other.spell_id], "Unequipped pending spell is rejected without dropping the next queued combo")
	Player_Global_Data.equipped_spells.append(longer)
	Player_Global_Data.spells_updated.emit()
	short.cast_time = 0
	short.upfront_cost = 60
	Player_Global_Data.p_curr_mana = 2
	before = casts.size()
	for key in ["up", "down", "right"]: player._add_sequence(key)
	check(casts.slice(before) == [longer.spell_id] and Player_Global_Data.p_curr_mana == 0, "Unaffordable prefix cannot block an affordable longer combo")
	short.cast_time = .4
	short.upfront_cost = 2
	Player_Global_Data.p_curr_mana = 100
	for key in ["up", "down", "right"]: player._add_sequence(key)
	player._clear_sequence()
	check(player.casting.state == SpellCastingComponent.State.PREPARING and player.casting._queue.size() == 1 and player.spell_string.is_empty() and Player_Global_Data.p_curr_mana == 98, "Clear preserves accepted requests and their upfront payment")
	player.cancel_active_casting()
	check(player.casting.state == SpellCastingComponent.State.IDLE and player.casting._queue.is_empty() and Player_Global_Data.p_curr_mana == 100, "Explicit cancellation clears queue and refunds preparation")
	var resolver := IncantationResolver.new()
	var catalogue: Array[SpellData] = [short, longer, other]
	resolver.rebuild(catalogue)
	resolver.push("up")
	check(not resolver.accepts("left") and resolver.push("left") == null and resolver.sequence.is_empty(), "A partial mistyped combo cannot silently restart another spell")
	resolver.strategy = IncantationResolver.Strategy.CONFIRMATION
	resolver.push("up")
	check(resolver.push("down") == null and resolver.confirm() == short, "Explicit confirmation mode remains available")
	Player_Global_Data.p_curr_health = 400
	Player_Global_Data.take_damage(100)
	Player_Global_Data.restore_health(999)
	check(Player_Global_Data.p_curr_health == 400, "Damage and healing respect the new 400 HP cap")
	player.queue_free()
	await get_tree().process_frame
	print("PLAYER_COMBO_CHAINS: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
