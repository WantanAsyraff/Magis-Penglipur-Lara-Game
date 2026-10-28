extends Node

var checks := 0
var failures := 0
var events: Array[Dictionary] = []

func completed_count(chain: int = -1) -> int:
	return events.filter(func(event): return event.status == SpellCastingComponent.RequestStatus.COMPLETED and (chain == -1 or event.chain == chain)).size()

func visible_keys(ui: IncantationAssistant) -> Array[String]:
	var result: Array[String] = []
	for direction in ui.direction_icons:
		if ui.direction_icons[direction].visible: result.append(direction)
	return result

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func definition(id: String, keys: Array[String]) -> SpellData:
	var spell := SpellData.new()
	spell.spell_id = id
	spell.spell_name = id
	spell.spell_incantation = keys
	spell.delivery = SpellData.Delivery.SELF
	spell.upfront_cost = 2
	spell.recovery_time = 0
	var heal := HealEffect.new()
	heal.amount = 1
	spell.effects = [heal]
	return spell

func _ready() -> void:
	await get_tree().process_frame
	var a := definition("A", ["down", "left", "down"])
	var b := definition("B", ["down", "left", "down", "left"])
	var c := definition("C", ["down", "left", "down", "left", "down"])
	var branch := definition("Branch", ["down", "left", "right"])
	var restart := definition("Restart", ["up", "right"])
	var spells: Array[SpellData] = [c, branch, b, restart, a]
	var resolver := IncantationResolver.new()
	resolver.rebuild(spells)
	check(resolver.get_valid_next_keys() == ["up", "down"], "Empty prefix returns equipped starting keys")
	check(resolver.get_matching_spells().size() == 5, "Empty prefix discovers all equipped spells")
	resolver.push("down")
	check(resolver.get_valid_next_keys() == ["left"], "Partial prefix suggests only accepted input")
	check(resolver.get_current_exact_match() == null, "Incomplete prefix is not an exact spell")
	resolver.push("left")
	check(resolver.get_valid_next_keys() == ["down", "right"], "Branching prefix exposes both branches")
	check(resolver.push("down") == a and resolver.get_current_exact_match() == a, "Exact prefix casts immediately and remains queryable")
	check(resolver.get_reachable_chain_spells() == [b, c], "Continuation ordering uses fewest remaining directions")
	check(resolver.get_valid_next_keys() == ["up", "down", "left"], "Valid next inputs include existing completed-prefix restart behavior")
	check(resolver.get_continuation_keys() == ["left"] and resolver.get_restart_keys() == ["up", "down"], "Continuation and independent restart are distinguished")
	var snapshot := resolver.get_sequence_snapshot()
	for i in 30:
		resolver.get_valid_next_keys()
		resolver.get_current_exact_match()
		resolver.get_matching_spells()
		resolver.get_reachable_chain_spells()
	check(resolver.sequence == snapshot and resolver._pending == null, "All prediction queries leave state and pending resolution unchanged")
	snapshot.clear()
	check(resolver.sequence.size() == 3, "Sequence snapshots cannot mutate resolver input")
	check(resolver.push("left") == b and resolver.push("down") == c and resolver.sequence.is_empty(), "Three exact prefix matches cast and terminal sequence clears")
	resolver.push("down")
	check(resolver.push("right") == null and resolver.sequence.is_empty(), "Invalid partial continuation follows clear policy")
	resolver.rebuild([restart])
	check(resolver.get_valid_next_keys() == ["up"], "Equipment rebuild replaces predictions")
	var duplicate := definition("Z", a.spell_incantation)
	resolver.rebuild([duplicate, a])
	check(resolver.validation_errors.size() == 1, "Duplicate equipped sequences have explicit diagnostics")
	for key in a.spell_incantation: resolver.push(key)
	resolver.rebuild([a, duplicate])
	check(resolver.get_matching_spells() == [a], "Exact collision selection is stable by spell ID")
	var long_keys: Array[String] = []
	for i in 32: long_keys.append("down")
	var long_spell := definition("Long", long_keys)
	resolver.rebuild([long_spell])
	for i in 31: resolver.push("down")
	check(resolver.get_reachable_chain_spells() == [long_spell] and resolver.push("down") == long_spell, "Authored long incantations have no fixed prefix-depth limit")
	Player_Global_Data.learned_spells.assign(spells)
	Player_Global_Data.equipped_spells.assign(spells)
	Player_Global_Data.combat_mode = true
	Player_Global_Data.assistance_mode = 0
	Player_Global_Data.p_curr_health = 100
	Player_Global_Data.p_curr_mana = 100
	var player: Player = load("res://components/characters/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.casting.set_physics_process(false)
	player.hitbox.set_physics_process(false)
	var ui: IncantationAssistant = player.chain_assistant
	player.casting.request_status.connect(func(id, chain, spell, status, reason): events.append({"id": id, "chain": chain, "spell": spell, "status": status, "reason": reason}))
	check(not ui.visible, "Assistant hidden outside stance")
	player._enter_casting_stance()
	check(ui.visible and visible_keys(ui) == ["up", "down"], "Guided assistant appears in stance")
	player._add_sequence("down")
	check(visible_keys(ui) == ["left"] and ui.direction_icons.left.texture == ui.ICONS.left, "Only the actual next direction is shown")
	player._add_sequence("left")
	check(visible_keys(ui) == ["down", "right"], "Branching prefix displays only eligible next icons")
	check(player.incantations.get_reachable_chain_spells()[0] == a, "Nearest prediction deterministically ordered")
	a.cast_time = 0.5
	player._add_sequence("down")
	var first_id: int = events.back().id
	var first_chain: int = events.back().chain
	check(player.spell_label.text.contains("Preparing") and completed_count() == 0, "Preparation never displays false Cast or chain success")
	player._add_sequence("left")
	check(player.spell_label.text.contains("Queued") and Player_Global_Data.p_curr_mana == 98, "Queued result is distinct and unpaid")
	player._add_sequence("down")
	check(player.casting._queue.size() == 2 and completed_count() == 0, "Terminal chain clears input while two accepted requests remain queued")
	check(visible_keys(ui) == ["up", "down"], "Terminal resolver reset displays valid starting icons")
	player._clear_sequence()
	check(player.casting.state == SpellCastingComponent.State.PREPARING and player.casting._queue.size() == 2, "Clear input leaves preparation and queue intact")
	player._add_sequence("up")
	check(visible_keys(ui) == ["right"], "New incomplete incantation displays its own next key")
	player._add_sequence("right")
	check(events.back().chain != first_chain, "Independent incantation gets a new chain identity")
	player.casting._physics_process(0.5)
	check(completed_count(first_chain) == 1 and player.spell_label.text.contains("Cast!"), "Successful execution increments original chain after input reset")
	check(player.casting.context.request_id == first_id, "Cast context correlates to the original preparation request")
	player.casting._physics_process(0)
	player.casting._physics_process(0)
	check(completed_count(first_chain) == 3 and Player_Global_Data.p_curr_mana == 94, "Three successful chain spells pay independently and count three")
	player.casting._physics_process(0)
	check(completed_count(first_chain) == 3 and completed_count(events.back().chain) == 1, "Later chain completion preserves both chain identities")
	player._clear_sequence()
	for key in ["down", "left", "down", "left"]: player._add_sequence(key)
	var queued_id: int = events.back().id
	Player_Global_Data.p_curr_mana = 0
	player.casting._physics_process(0.5)
	player.casting._physics_process(0)
	check(events.back().id == queued_id and events.back().status == SpellCastingComponent.RequestStatus.FAILED and events.back().reason == "Not enough mana", "Deferred mana failure updates the correct queued request")
	check(player.spell_label.text.contains("Not enough mana"), "UI displays actual execution failure")
	Player_Global_Data.p_curr_mana = 100
	player.casting.cooldowns[a.spell_id] = 3
	player._clear_sequence()
	for key in a.spell_incantation: player._add_sequence(key)
	check(events.back().status == SpellCastingComponent.RequestStatus.FAILED and player.spell_label.text.contains("cooling down"), "Cooldown rejection never shows successful cast")
	check(player.casting.preview_restriction(a, 100).contains("Ready in"), "Cooldown forecast reads real casting cooldown")
	player.casting.cooldowns.clear()
	player.casting.enqueue_cast(a, Vector2.ZERO, Vector2.RIGHT, [], 300)
	for i in 8: player.casting.enqueue_cast(b, Vector2.ZERO, Vector2.RIGHT, [], 300)
	check(not player.casting.enqueue_cast(c, Vector2.ZERO, Vector2.RIGHT, [], 300) and events.back().reason == "Cast queue is full", "Queue saturation reports a failed distinct request")
	player.cancel_active_casting()
	check(events.filter(func(e): return e.chain == 300 and e.status == SpellCastingComponent.RequestStatus.CANCELLED).size() == 9, "Explicit cancellation terminates active and all eight queued requests")
	for restriction in ["silence", "stun"]:
		player.hitbox.effects.apply(restriction, 1, {})
		check(not player.casting.enqueue_cast(a, Vector2.ZERO, Vector2.RIGHT) and events.back().status == SpellCastingComponent.RequestStatus.FAILED, restriction + " prevents execution")
		player.hitbox.effects.clear()
	player.casting.enqueue_cast(a, Vector2.ZERO, Vector2.RIGHT, [], 400)
	player.casting.enqueue_cast(b, Vector2.ZERO, Vector2.RIGHT, [], 400)
	player.casting.cancel("Interrupted by damage")
	check(events.filter(func(e): return e.chain == 400 and e.status == SpellCastingComponent.RequestStatus.INTERRUPTED).size() == 1, "Damage interruption correlates active request")
	Player_Global_Data.p_curr_mana = 100
	a.cast_time = 0
	a.is_channelled = true
	a.channel_duration = 1
	a.mana_per_second = 3
	player.casting.enqueue_cast(a, Vector2.ZERO, Vector2.RIGHT, [], 500)
	check(events.back().status == SpellCastingComponent.RequestStatus.CHANNELING and player.spell_label.text.contains("Channeling"), "Channel request has correlated channeling feedback")
	player.casting._physics_process(0.2)
	check(is_equal_approx(Player_Global_Data.p_curr_mana, 97.4), "Channel forecast uses the actual per-second payment model")
	player.cancel_active_casting()
	check(completed_count(500) == 0 and is_equal_approx(Player_Global_Data.p_curr_mana, 99.4), "Explicit channel cancellation refunds preparation but never spent channel mana or shows false completion")
	a.is_channelled = false
	a.cast_time = 0.5
	player.casting.enqueue_cast(a, Vector2.ZERO, Vector2.RIGHT, [], 501)
	player.casting.enqueue_cast(b, Vector2.ZERO, Vector2.RIGHT, [], 501)
	var cooling_request: int = events.back().id
	player.casting.cooldowns[b.spell_id] = 3
	player.casting._physics_process(0.5)
	player.casting._physics_process(0)
	check(events.back().id == cooling_request and events.back().reason == "Spell is cooling down", "Queued cooldown rejection keeps its original request identity")
	player.casting.cooldowns.clear()
	player._enter_casting_stance()
	Player_Global_Data.assistance_mode = 1
	Player_Global_Data.assistance_changed.emit(1)
	check(not ui.visible, "Minimal mode hides optional next-key guidance")
	Player_Global_Data.assistance_mode = 2
	Player_Global_Data.assistance_changed.emit(2)
	check(not ui.visible, "Off hides optional assistant")
	Player_Global_Data.assistance_mode = 0
	Player_Global_Data.assistance_changed.emit(0)
	for i in 100:
		player._clear_sequence()
		player._add_sequence("down")
	await get_tree().process_frame
	check(ui.next_row.get_child_count() == 4 and visible_keys(ui) == ["left"], "Rapid input does not accumulate stale UI children")
	check(ui.get_child_count() == 1 and ui.direction_icons.left.custom_minimum_size == Vector2(64, 64), "Assistant contains only enlarged key icons without a panel or text")
	Dialogic.timeline_started.emit()
	check(not ui.visible, "Dialogue suspends assistant")
	Dialogic.timeline_ended.emit()
	check(ui.visible, "Dialogue end restores stance presentation")
	get_tree().paused = true
	check(not ui.visible, "Pause suspends assistant")
	get_tree().paused = false
	check(ui.visible, "Unpause restores stance presentation")
	var settings_path := "user://assistant-test-%d.cfg" % OS.get_process_id()
	check(Player_Global_Data.set_assistance_mode(1, settings_path) == OK, "Assistance preference saves successfully")
	Player_Global_Data.assistance_mode = 0
	Player_Global_Data.load_assistance_settings(settings_path)
	check(Player_Global_Data.assistance_mode == 1, "Assistance preference reloads from disk")
	var keybind_path := "user://assistant-keybind-test-%d.cfg" % OS.get_process_id()
	var saved_up := InputMap.action_get_events("incantation_up")
	InputMap.action_erase_events("incantation_up")
	var physical := InputEventKey.new()
	physical.physical_keycode = KEY_I
	InputMap.action_add_event("incantation_up", physical)
	var settings: Control = load("res://scenes/ui/menus/settings-menu.tscn").instantiate()
	add_child(settings)
	settings._save_to_file(keybind_path)
	InputMap.action_erase_events("incantation_up")
	load("res://scenes/ui/menus/settings_menu.gd").load_from_file(keybind_path)
	check(InputMap.action_get_events("incantation_up")[0].physical_keycode == KEY_I, "Saving assistance settings preserves physical directional bindings")
	check(settings.ACTIONS.any(func(entry): return entry[0] == "cancel_casting") and InputMap.action_get_events("cancel_casting").is_empty(), "Cast cancellation is configurable without adding a conflicting default key")
	InputMap.action_erase_events("incantation_up")
	for event in saved_up: InputMap.action_add_event("incantation_up", event)
	settings.queue_free()
	DirAccess.remove_absolute(keybind_path)
	DirAccess.remove_absolute(settings_path)
	Player_Global_Data.assistance_mode = 0
	Player_Global_Data.assistance_changed.emit(0)
	player._exit_casting_stance()
	check(not ui.visible, "Exit stance hides assistant")
	player._enter_casting_stance()
	player._on_died()
	check(not ui.visible and player.incantations.sequence.is_empty(), "Death hides and clears assistant safely")
	player.queue_free()
	await get_tree().process_frame
	print("INCANTATION_ASSISTANT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
