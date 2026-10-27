extends Node
const Actor = preload("res://tests/spell-regression.gd").TestActor
const BASE = preload("res://components/NPCs/enemies/Enemy.tscn")
const MONSTERS = [preload("res://components/NPCs/enemies/zalam-manifestations/fishes/snakehead-murrel.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/dragonfly.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/stone-crab.tscn"), preload("res://components/NPCs/enemies/zalam-manifestations/bakau/crocodile.tscn")]
var checks := 0
var failures := 0
var completed := false
var box: Node2D
var player: CharacterBody2D
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func clear_world() -> void:
	if is_instance_valid(box): box.free()
	box = Node2D.new()
	add_child(box)
	player = Actor.new()
	player.add_to_group("player")
	box.add_child(player)
	player.position = Vector2(10000, 0)
func reset_state() -> void:
	QuestManager.persistence_enabled = false
	QuestManager.conversations = QuestConversationStore.new()
	QuestManager.live_offers.clear()
	QuestManager._save_timer.stop()
	QuestManager._active_instances.clear()
	QuestManager._npc_instance_map.clear()
	QuestManager._quest_active_count.clear()
	QuestManager.reward_claims.clear()
	QuestManager.seen_events.clear()
	QuestManager.world_flags.clear()
	QuestManager.pending_events.clear()
	QuestManager.active_owner_id = "local"
	QuestManager.selected_instance_id = ""
	Player_Global_Data.completed_quests.clear()
	Inventory_Manager.reset()
	Inventory_Manager.max_slots = 64
	clear_world()
func item(id: String) -> ItemData:
	return QuestManager.registry.items[id]
func spawn(scene: PackedScene) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	box.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.hitbox.set_physics_process(false)
	return enemy
func kill(scene: PackedScene) -> Enemy:
	var enemy := spawn(scene)
	enemy.hitbox.receive_damage(1000000, player)
	return enemy
func discard_drops() -> void:
	for node in box.get_children():
		if node is DroppedItem: node.queue_free()
func loot_pickup(id: String, quantity: int) -> int:
	var drop := DroppedItem.new()
	# Use the actual production scene, including pickup/magnet components.
	drop.free()
	drop = load("res://components/loot/dropped-item/dropped-item.tscn").instantiate()
	drop.loot_data = LootData.new()
	drop.loot_data.item = item(id)
	drop.quantity = quantity
	box.add_child(drop)
	drop.set_physics_process(false)
	return drop.pickup(player)
func active(id: String) -> QuestInstance:
	var instance := QuestManager.offer_quest(id, "bakau_field_researcher")
	if instance: QuestManager.accept_quest(instance.instance_id)
	return instance
func custom(id: String, objectives: Array[QuestObjectiveData]) -> QuestData:
	var data := QuestData.new()
	data.quest_id = id
	data.title = id
	data.objectives = objectives
	QuestManager.registry.quests[id] = data
	return data
func objective(id: String, kind: QuestObjectiveData.ObjectiveType, target: String, amount: int = 1) -> QuestObjectiveData:
	var obj := QuestObjectiveData.new()
	obj.objective_id = id
	obj.description = id
	obj.type = kind
	obj.target_id = target
	obj.required_amount = amount
	return obj
func finish_dialogue_later(component: DialogicComponent, cancel: bool) -> void:
	await frames()
	if cancel: component.close()
	else: Dialogic.end_timeline()
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await run()
	check(completed, "Quest and loot suite reached final assertion")
	print("QUEST_PIPELINE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
func run() -> void:
	reset_state()
	check(QuestManager.registry.errors.is_empty() and QuestManager.registry.quests.size() == 14, "Fourteen valid registered quests")
	check(QuestData.Faculty.COMPUTER_SCIENCE == 2 and QuestData.Faculty.TECHNOLOGY_SCIENCE == 6, "Faculty numeric compatibility retained")
	var xp_spec := [120, 80, 100, 90, 130, 100, 280, 220, 240, 200]
	var qty_spec := [2, 4, 1, 4, 4, 4, 6, 6, 6, 6]
	var prereq_spec := [0, 1, 0, 3, 0, 5, 0, 6, 7, 8]
	var item_spec := ["craft_cons_001", "craft_cons_004", "craft_cons_001", "craft_cons_004", "craft_cons_001", "craft_cons_001", "craft_cons_001", "craft_cons_004", "craft_cons_001", "craft_cons_004"]
	var amount_spec := [[8], [5], [6], [3, 2], [10], [4, 3], [5, 4, 6], [2, 2, 2], [12, 8], [3, 2, 1]]
	var target_spec := [
		[["enemy_mangroove_snakehead_murrel"]], [["drop_001", "drop_002", "drop_003"]],
		[["enemy_mangroove_dragonfly"]], [["drop_005"], ["drop_006"]],
		[["enemy_mangroove_stone_crab"]], [["drop_007"], ["drop_008"]],
		[["enemy_mangroove_snakehead_murrel"], ["enemy_mangroove_dragonfly"], ["enemy_mangroove_stone_crab"]],
		[["drop_001"], ["drop_004"], ["drop_007"]],
		[["enemy_mangroove_snakehead_murrel"], ["enemy_mangroove_stone_crab"]],
		[["drop_002"], ["drop_006"], ["drop_008"]]]
	for i in 10:
		var id := "quest_bakau_%03d" % (i + 1)
		var data: QuestData = QuestManager.registry.quests[id]
		var amounts: Array = []
		var targets: Array = []
		for obj in data.objectives:
			amounts.append(obj.required_amount)
			targets.append(obj.targets())
		check(data.reward_xp == xp_spec[i] and data.reward_items.size() == 1 and data.reward_items[0].min_quantity == qty_spec[i] and data.reward_items[0].max_quantity == qty_spec[i] and data.reward_items[0].item.item_id == item_spec[i], "Exact XP/item rewards: " + id)
		check(data.prerequisite_quest_ids == (["quest_bakau_%03d" % prereq_spec[i]] if prereq_spec[i] else []) and amounts == amount_spec[i] and targets == target_spec[i], "Exact prerequisites, targets and quantities: " + id)
		check(data.region_id == &"bakau" and data.faculty == 6 and data.hand_in_npc_id == "bakau_field_researcher", "Stable region/pool/hand-in: " + id)
	for i in 13:
		var id := "drop_%03d" % (i + 1)
		check(QuestManager.registry.items.has(id) and not item(id).description.is_empty() and item(id).ingredient_1 == null, "Valid master-sheet drop without invented recipe: " + id)
	for scene in MONSTERS:
		var enemy := spawn(scene)
		check(enemy.definition.validate().is_empty() and enemy.definition.quest_enemy_id == String(enemy.definition.enemy_id), "Canonical functional monster: " + enemy.enemy_name)
		var expected: int = [3, 3, 4, 3][MONSTERS.find(scene)]
		var expected_ids: Array = [["drop_001", "drop_002", "drop_003"], ["drop_004", "drop_005", "drop_006"], ["drop_007", "drop_008", "drop_009", "drop_010"], ["drop_011", "drop_012", "drop_013"]][MONSTERS.find(scene)]
		var actual_ids: Array = []
		for loot in enemy.definition.loot: actual_ids.append(loot.item.item_id)
		check(enemy.definition.loot.size() == expected and actual_ids == expected_ids and enemy.definition.loot.all(func(l): return l.validate().is_empty()), "Independent valid loot mapping: " + enemy.enemy_name)
	clear_world()
	# All ten quests are accepted, progressed and handed in through the production board.
	var board := QuestBoard.new()
	box.add_child(board)
	board.dialogic.use_dialogic = false
	for i in 10:
		discard_drops()
		var id := "quest_bakau_%03d" % (i + 1)
		board.open()
		board.panel._select(id)
		board.panel._accept()
		QuestOfferDialog.current.decide("accept")
		board.close()
		var instance: QuestInstance
		for candidate in QuestManager.get_all_active():
			if candidate.quest_data.quest_id == id: instance = candidate
		check(instance != null and instance.status == QuestInstance.Status.ACTIVE, "Board accepts unlocked quest: " + id)
		var data := instance.quest_data
		for obj in data.objectives:
			if obj.type == QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY:
				var index := ["enemy_mangroove_snakehead_murrel", "enemy_mangroove_dragonfly", "enemy_mangroove_stone_crab"].find(obj.targets()[0])
				for n in obj.required_amount: kill(MONSTERS[index])
			else:
				if obj.targets().size() > 1:
					check(loot_pickup("drop_001", 2) == 2 and loot_pickup("drop_002", 1) == 1 and loot_pickup("drop_003", 2) == 2, "Mixed fish acquisition accepts 2/1/2 combination")
				else: check(loot_pickup(obj.targets()[0], obj.required_amount) == obj.required_amount, "Confirmed specimen pickup: " + obj.description)
		check(instance.status == QuestInstance.Status.COMPLETE, "Actual enemy/pickup events complete objectives: " + id)
		var xp: float = Player_Global_Data.player_exp
		var reward_id: String = data.reward_items[0].item.item_id
		var quantity := Inventory_Manager.get_item_quantity(reward_id)
		board.open()
		board.panel._select(id)
		board.panel._claim()
		board.close()
		check(instance.reward_claimed and QuestManager.is_quest_complete(id) and Player_Global_Data.player_exp == xp + xp_spec[i] and Inventory_Manager.get_item_quantity(reward_id) == quantity + qty_spec[i], "Board hand-in delivers exact reward once: " + id)
		check(not QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and Player_Global_Data.player_exp == xp + xp_spec[i], "Repeated hand-in cannot duplicate: " + id)
		await frames()
	check(Player_Global_Data.completed_quests.size() == 10, "All ten Bakau quests playable through real board/events/inventory")
	# Preserve all four original FLAC identities and complete via NPC component callbacks.
	reset_state()
	for id in ["defeat_flower_quest", "defeat_tree_quest", "gather_quest_leaves", "gather_quest_branches"]:
		var npc := CharacterBody2D.new()
		var component := QuestNPCComponent.new()
		component.npc_id = "flac_" + id
		component.faculty = QuestData.Faculty.COMPUTER_SCIENCE
		npc.add_child(component)
		box.add_child(npc)
		component.setup_quest()
		var instance: QuestInstance = component._instance
		check(instance != null and instance.quest_data.quest_id == id, "FLAC identity restored through NPC: " + id)
		QuestManager.decide_offer(QuestManager.present_offer(instance.instance_id, component.npc_id), "accept")
		for obj in instance.quest_data.objectives:
			if obj.type == QuestObjectiveData.ObjectiveType.DEFEAT_ENEMY:
				for n in obj.required_amount: kill(load("res://components/NPCs/enemies/zalam-manifestations/" + ("bunga/bunga" if obj.target_id == "bunga" else "pohon/pohon") + ".tscn"))
			else: loot_pickup(obj.target_id, obj.required_amount)
		check(instance.status == QuestInstance.Status.COMPLETE, "FLAC objective events complete: " + id)
		var xp: float = Player_Global_Data.player_exp
		var money: float = Player_Global_Data.p_curr_ringgit
		component.confirm_complete_dialogue_done()
		component._grant_rewards()
		check(instance.reward_claimed and Player_Global_Data.player_exp == xp + instance.quest_data.reward_xp and Player_Global_Data.p_curr_ringgit == money + instance.quest_data.reward_currency, "FLAC NPC reward is centralized and once-only: " + id)
		await frames()
	# Optional/dependent/grouped objectives use the common evaluator.
	reset_state()
	var first := objective("first", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "switch")
	var second := objective("second", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "switch")
	second.requires_objectives = ["first"]
	var optional := objective("optional", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "bonus")
	optional.is_optional = true
	var definition := custom("test_order", [first, second, optional])
	var instance := active(definition.quest_id)
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.OBJECT_INTERACTED, "switch"))
	check(instance.done("first") and not instance.done("second"), "One event cannot cascade through ordered objectives")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.OBJECT_INTERACTED, "switch"))
	check(instance.status == QuestInstance.Status.COMPLETE and not instance.done("optional"), "Optional objective does not block completion")
	var a := objective("a", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "a")
	var b := objective("b", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "b")
	a.group_id = &"choice"
	b.group_id = &"choice"
	definition = custom("test_group", [a, b])
	var group := QuestObjectiveGroup.new()
	group.group_id = &"choice"
	group.policy = QuestObjectiveGroup.Policy.ANY
	definition.objective_groups = [group]
	instance = active(definition.quest_id)
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.OBJECT_INTERACTED, "b"))
	check(instance.status == QuestInstance.Status.COMPLETE and not instance.done("a"), "ANY objective group supports alternatives")
	# A delivery alternative consumes only the completed route.
	reset_state()
	a = objective("shell", QuestObjectiveData.ObjectiveType.COLLECT_ITEM, "drop_007")
	b = objective("claw", QuestObjectiveData.ObjectiveType.COLLECT_ITEM, "drop_008")
	a.collection_mode = QuestObjectiveData.CollectionMode.DELIVERY
	b.collection_mode = QuestObjectiveData.CollectionMode.DELIVERY
	a.group_id = &"delivery_choice"
	b.group_id = &"delivery_choice"
	definition = custom("test_delivery_choice", [a, b])
	group = QuestObjectiveGroup.new()
	group.group_id = &"delivery_choice"
	group.policy = QuestObjectiveGroup.Policy.ANY
	definition.objective_groups = [group]
	instance = active(definition.quest_id)
	Inventory_Manager.pickup(item("drop_008"), 1)
	check(instance.status == QuestInstance.Status.COMPLETE and QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and Inventory_Manager.get_item_quantity("drop_008") == 0, "ANY delivery group consumes only the selected completed alternative")
	# Exact IDs, concurrent quests and source replay protection.
	reset_state()
	var cull := active("quest_bakau_001")
	var survey := active("quest_bakau_007")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_snakehead_murrel_extra"))
	check(cull.objective_progress.values()[0] == 0, "Enemy IDs match exactly rather than by substring")
	var defeated := kill(MONSTERS[0])
	defeated.hitbox.died.emit()
	defeated.get_node("EnemyQuestObserverComponent")._on_enemy_died()
	check(cull.objective_progress.values()[0] == 1 and survey.objective_progress["quest_bakau_007_1"] == 1, "One actual defeat advances both eligible quests once")
	var event := GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_snakehead_murrel", 1, "local", "replay")
	QuestManager.publish(event)
	QuestManager.publish(event)
	check(cull.objective_progress.values()[0] == 2, "Duplicate event receipt ignored")
	# Held and delivery modes are independent of cumulative progress.
	reset_state()
	var held := objective("held", QuestObjectiveData.ObjectiveType.COLLECT_ITEM, "drop_001", 2)
	held.collection_mode = QuestObjectiveData.CollectionMode.CURRENT_HELD
	definition = custom("test_held", [held])
	Inventory_Manager.add_item(item("drop_001"), 2)
	instance = active(definition.quest_id)
	check(instance.status == QuestInstance.Status.COMPLETE, "Current-held objectives reconcile on acceptance")
	Inventory_Manager.remove_item(item("drop_001"), 1)
	check(instance.status == QuestInstance.Status.ACTIVE and instance.objective_progress.held == 1, "Removing held items safely reopens readiness")
	held = held.duplicate() as QuestObjectiveData
	held.collection_mode = QuestObjectiveData.CollectionMode.DELIVERY
	definition = custom("test_delivery", [held])
	instance = active(definition.quest_id)
	Inventory_Manager.add_item(item("drop_001"), 1)
	check(QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and Inventory_Manager.get_item_quantity("drop_001") == 0, "Delivery consumes exact held requirement at claim")
	# Failed/partial pickups never inflate progress; legacy scene hooks are inert.
	reset_state()
	Player_Global_Data.completed_quests.append("quest_bakau_001")
	instance = active("quest_bakau_002")
	Inventory_Manager.add_item(item("drop_001"), 99)
	instance.objective_progress["quest_bakau_002_1"] = 0
	instance.reconcile()
	check(loot_pickup("drop_001", 2) == 0 and instance.objective_progress.values()[0] == 0, "Full stack rejects pickup without progress")
	Inventory_Manager.remove_item(item("drop_001"), 1)
	check(loot_pickup("drop_001", 3) == 1 and instance.objective_progress.values()[0] == 1, "Partial stack reports only actual acquired quantity")
	var before := Inventory_Manager.get_item_quantity("drop_002")
	Inventory_Manager.pickup(item("drop_002"), 1, "pickup-receipt")
	Inventory_Manager.pickup(item("drop_002"), 1, "pickup-receipt")
	check(Inventory_Manager.get_item_quantity("drop_002") == before + 1 and instance.objective_progress.values()[0] == 2, "Inventory receipt prevents duplicate pickup and quest credit")
	# NPC departure keeps active/complete hand-in associations and progress.
	QuestManager.release_npc("bakau_field_researcher")
	check(QuestManager.get_instance_for_npc("bakau_field_researcher") == instance and instance.status == QuestInstance.Status.ACTIVE, "NPC release retains accepted quest association")
	Inventory_Manager.pickup(item("drop_003"), 3)
	check(instance.status == QuestInstance.Status.COMPLETE, "Mixed collection completes after resumed interaction")
	check(not QuestManager.try_hand_off(instance.instance_id, "wrong_npc"), "Wrong hand-in NPC rejected")
	# Atomic reward plan retains pending claims when capacity is exhausted.
	Inventory_Manager.max_slots = Inventory_Manager.inventory.size()
	var xp: float = Player_Global_Data.player_exp
	check(not QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and not instance.reward_claimed and Player_Global_Data.player_exp == xp and instance.pending_claim.contains("Inventory"), "Full inventory leaves a recoverable pending reward")
	Inventory_Manager.max_slots = 64
	check(QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher"), "Pending reward succeeds after room is made")
	# Save/load restores progress, inventory and claim values as one versioned bundle.
	QuestManager.persistence_enabled = true
	QuestManager.save_path = "user://quest-regression-v2.json"
	check(QuestManager.save_game(), "Versioned quest/inventory snapshot saves atomically")
	var saved_xp: float = Player_Global_Data.player_exp
	var saved_items := Inventory_Manager.get_item_quantity("craft_cons_004")
	Inventory_Manager.inventory.clear()
	Player_Global_Data.player_exp = 0
	QuestManager._active_instances.clear()
	check(QuestManager.load_game() and Player_Global_Data.player_exp == saved_xp and Inventory_Manager.get_item_quantity("craft_cons_004") == saved_items, "Save restores XP, inventory and quest state together")
	instance = QuestManager.get_instance(instance.instance_id)
	check(instance != null and instance.reward_claimed and not QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher"), "Reloaded claim marker prevents reward replay")
	var replay_quantity := Inventory_Manager.get_item_quantity("drop_002")
	check(Inventory_Manager.pickup(item("drop_002"), 1, "pickup-receipt") == 0 and Inventory_Manager.get_item_quantity("drop_002") == replay_quantity, "Pickup receipts survive save/load")
	var snapshot := QuestSaveService.encode(QuestManager)
	var broken := snapshot.duplicate(true)
	broken.version = 999
	check(QuestSaveService.stage(QuestManager, broken).is_empty(), "Unknown save version rejected without mutation")
	broken = snapshot.duplicate(true)
	broken.inventory.append({"item_id": "missing_item", "quantity": 1})
	check(QuestSaveService.stage(QuestManager, broken).is_empty() and Player_Global_Data.player_exp == saved_xp, "Unknown saved resource rejected without changing live state")
	# A failed disk write rolls back items, XP, currency and the claim together.
	QuestManager.persistence_enabled = false
	Player_Global_Data.completed_quests.append("quest_bakau_003")
	instance = active("quest_bakau_004")
	Inventory_Manager.pickup(item("drop_005"), 3)
	Inventory_Manager.pickup(item("drop_006"), 2)
	QuestManager.persistence_enabled = true
	QuestManager.save_path = "user://does-not-exist/subfolder/quest.json"
	xp = Player_Global_Data.player_exp
	before = Inventory_Manager.get_item_quantity("craft_cons_004")
	check(not QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and Player_Global_Data.player_exp == xp and Inventory_Manager.get_item_quantity("craft_cons_004") == before and not instance.reward_claimed, "Failed durable commit rolls back every reward mutation")
	QuestManager.save_path = "user://quest-regression-v2.json"
	check(QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher"), "Failed save leaves a claim that can be retried safely")
	# Outbox events saved before processing are replayed after recovery, once.
	QuestManager.persistence_enabled = false
	var world_obj := objective("flag", QuestObjectiveData.ObjectiveType.WORLD_FLAG_CHANGED, "sample_flag")
	definition = custom("test_outbox", [world_obj])
	instance = active(definition.quest_id)
	event = GameplayEvent.new(GameplayEvent.Type.WORLD_FLAG_CHANGED, "sample_flag", 1, "local", "durable-outbox")
	event.metadata.value = true
	QuestManager.pending_events.append(event.to_dict())
	check(QuestManager.save_game(), "Unprocessed durable event saved in outbox")
	check(QuestManager.load_game() and QuestManager.get_instance(instance.instance_id).status == QuestInstance.Status.COMPLETE and QuestManager.pending_events.is_empty(), "Load replays durable outbox into objectives")
	QuestManager.publish(event)
	check(QuestManager.get_instance(instance.instance_id).objective_progress.flag == 1, "Outbox receipt remains idempotent")
	# A next quest is actually offered/accepted rather than just logged.
	reset_state()
	var parent := custom("test_chain_parent", [objective("lever", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "lever")])
	var child := custom("test_chain_child", [objective("door", QuestObjectiveData.ObjectiveType.OBJECT_INTERACTED, "door")])
	parent.next_quest_id = child.quest_id
	parent.auto_accept_next = true
	child.prerequisite_quest_ids = [parent.quest_id]
	instance = active(parent.quest_id)
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.OBJECT_INTERACTED, "lever"))
	check(QuestManager.try_hand_off(instance.instance_id, "bakau_field_researcher") and QuestManager.get_instance_for_npc("bakau_field_researcher").quest_data == child and QuestManager.get_instance_for_npc("bakau_field_researcher").status == QuestInstance.Status.AVAILABLE, "Configured next-quest chain offers explicit decision after hand-in")
	# Recovery also repairs an interruption between the durable claim and chain offering.
	var child_instance := QuestManager.get_instance_for_npc("bakau_field_researcher")
	QuestManager._active_instances.erase(child_instance.instance_id)
	QuestManager.save_path = "user://quest-regression-v2.json"
	check(QuestManager.save_game() and QuestManager.load_game() and QuestManager.get_instance_for_npc("bakau_field_researcher").quest_data == child, "Load resumes a chain interrupted immediately after durable reward commit")
	# All remaining event types use a typed common route; real Magis calls publish events.
	reset_state()
	var force: SpellData = load("res://data/magis/spells/phys-force.tres")
	var cast_obj := objective("cast", QuestObjectiveData.ObjectiveType.SPELL_CAST, force.spell_id)
	var hit_obj := objective("hit", QuestObjectiveData.ObjectiveType.SPELL_HIT, force.spell_id)
	var status_obj := objective("status", QuestObjectiveData.ObjectiveType.STATUS_APPLIED, "slow")
	definition = custom("test_magis", [cast_obj, hit_obj, status_obj])
	instance = active(definition.quest_id)
	player.casting.request_cast(force, Vector2.ZERO, Vector2.RIGHT)
	player.casting._physics_process(force.cast_time + .01)
	var target := spawn(MONSTERS[0])
	var projectile: MagicProjectile
	for node in get_tree().get_nodes_in_group("spell_projectile"):
		if node.source == player: projectile = node
	projectile._on_body_entered(target)
	var slow := ApplyStatusEffect.new()
	slow.status = "slow"
	slow.magnitude = .5
	slow.execute(SpellCastContext.new(player, force), target)
	check(instance.status == QuestInstance.Status.COMPLETE, "Actual casting, impact and status application publish quest events")
	var interaction := objective("talk", QuestObjectiveData.ObjectiveType.TALK_TO_NPC, "test_npc")
	var dialogue := objective("dialogue", QuestObjectiveData.ObjectiveType.DIALOGUE_COMPLETED, "test_npc")
	var location := objective("place", QuestObjectiveData.ObjectiveType.REACH_LOCATION, "test_location")
	var flag := objective("flag", QuestObjectiveData.ObjectiveType.WORLD_FLAG_CHANGED, "test_flag")
	definition = custom("test_events", [interaction, dialogue, location, flag])
	instance = active(definition.quest_id)
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.NPC_INTERACTED, "test_npc"))
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.DIALOGUE_COMPLETED, "test_npc"))
	var trigger := QuestWorldEvent.new()
	trigger.target_id = "test_location"
	box.add_child(trigger)
	trigger.trigger(player)
	QuestManager.set_world_flag("test_flag", true)
	check(instance.status == QuestInstance.Status.COMPLETE, "NPC/dialogue/location/world events use the same evaluator")
	# Owner isolation and authority gates apply to quest events and claims.
	reset_state()
	var local := active("quest_bakau_001")
	var remote := QuestManager.offer_quest("quest_bakau_001", "remote_board", "other_player")
	QuestManager.accept_quest(remote.instance_id, "other_player")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_snakehead_murrel", 8, "other_player"))
	check(remote.status == QuestInstance.Status.COMPLETE and local.objective_progress.values()[0] == 0 and not QuestManager.try_hand_off(remote.instance_id, "remote_board"), "Other-player progress and reward claims stay isolated")
	var peer := ENetMultiplayerPeer.new()
	check(peer.create_client("127.0.0.1", 19995) == OK, "Quest authority test client created")
	multiplayer.multiplayer_peer = peer
	check(not QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_snakehead_murrel")) and Inventory_Manager.pickup(item("drop_001"), 1) == 0, "Client cannot forge quest progress or inventory acquisition")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer.close()
	check(GameplayEvent.from_dict({"type": 0, "target_id": "bunga", "quantity": 1, "owner_id": "local"}) == null, "Malformed recovered event cannot manufacture a new replay receipt")
	# Invalid definitions/cycles are diagnosed without recursion overflow.
	definition = QuestData.new()
	definition.quest_id = "invalid"
	definition.title = "Invalid"
	first = objective("bad", QuestObjectiveData.ObjectiveType.COLLECT_ITEM, "missing_item")
	first.requires_objectives = ["bad"]
	definition.objectives = [first]
	check(not QuestManager.registry.validate(definition).is_empty(), "Unknown target and objective cycle rejected")
	# Independent drop rolls, quantity bounds, rarity and physical pickups.
	reset_state()
	var data := (load("res://data/npc/enemies/definitions/bakau/stone-crab.tres") as EnemyData).duplicate(true) as EnemyData
	var yes := LootData.new()
	yes.item = item("drop_007")
	yes.drop_chance = 1
	yes.min_quantity = 2
	yes.max_quantity = 3
	var no := LootData.new()
	no.item = item("drop_009")
	no.drop_chance = 0
	data.loot = [yes, no]
	var enemy := BASE.instantiate() as Enemy
	enemy.enemy_data = data
	box.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.hitbox.receive_damage(10000, player)
	enemy.hitbox.died.emit()
	var drops: Array[DroppedItem] = []
	for node in box.get_children():
		if node is DroppedItem: drops.append(node)
	check(drops.size() == 1 and drops[0].loot_data.item.item_id == "drop_007" and drops[0].quantity in [2, 3], "Independent guaranteed/zero rolls and quantity limits respected once")
	check(drops[0].global_position == enemy.global_position, "Loot spawns at actual world death location")
	var qty := drops[0].quantity
	check(drops[0].pickup(player) == qty and drops[0].pickup(player) == 0 and Inventory_Manager.get_item_quantity("drop_007") == qty, "Production dropped item can be acquired only once")
	var crab: EnemyData = load("res://data/npc/enemies/definitions/bakau/stone-crab.tres")
	check(crab.loot[2].item.item_id == "drop_009" and crab.loot[2].drop_chance < crab.loot[0].drop_chance and crab.loot[2].rarity == 2, "Crab Stone is explicitly rarer than common shell")
	# Every catalogue item can actually emerge from its assigned source.
	for kind in 4:
		clear_world()
		var scene_enemy := spawn(MONSTERS[kind])
		var loot_component := scene_enemy.get_node("EnemyLootComponent") as EnemyLootComponent
		var found := {}
		seed(13579 + kind)
		for roll in 160:
			loot_component._process_all_loot()
			for node in box.get_children():
				if node is DroppedItem:
					found[node.loot_data.item.item_id] = true
					node.free()
		check(found.size() == scene_enemy.definition.loot.size(), "Actual source rolls can yield every mapped drop: " + scene_enemy.enemy_name)
	# An explicit legacy bundle remains bundled, not an implicit independent table.
	clear_world()
	enemy = spawn(MONSTERS[0])
	var bundle := LootData.new()
	bundle.item = item("drop_001")
	bundle.drop_chance = 1
	bundle.extra_drops = [item("drop_002"), item("drop_003")]
	enemy.get_node("EnemyLootComponent")._process_loot_entry(bundle)
	var bundled := 0
	for node in box.get_children():
		if node is DroppedItem: bundled += 1
	check(bundled == 3, "Explicit extra_drops bundle compatibility retained")
	# Real overlap acquisition includes the delayed production pickup component.
	reset_state()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	player.add_child(collision)
	var physical_drop: DroppedItem = load("res://components/loot/dropped-item/dropped-item.tscn").instantiate()
	physical_drop.loot_data = yes
	physical_drop.quantity = 2
	box.add_child(physical_drop)
	physical_drop.position = player.position
	physical_drop.set_physics_process(false)
	for tick in 24: await get_tree().physics_frame
	check(Inventory_Manager.get_item_quantity("drop_007") == 2 and not is_instance_valid(physical_drop), "Physical overlap and pickup delay acquire actual spawned loot")
	# Cancelling the real Dialogic sequence must neither accept nor claim.
	reset_state()
	var npc := CharacterBody2D.new()
	var dialogue_component := DialogicComponent.new()
	dialogue_component.name = "DialogicComponent"
	npc.add_child(dialogue_component)
	var quest_component := QuestNPCComponent.new()
	quest_component.npc_id = "cancellation_npc"
	quest_component.faculty = QuestData.Faculty.COMPUTER_SCIENCE
	npc.add_child(quest_component)
	box.add_child(npc)
	quest_component._dialogic_comp = dialogue_component
	quest_component.setup_quest()
	instance = quest_component._instance
	finish_dialogue_later(dialogue_component, true)
	await quest_component.interact()
	check(instance.status == QuestInstance.Status.AVAILABLE and Player_Global_Data.p_moveable, "Cancelled real offer dialogue leaves quest unaccepted and movement restored")
	QuestManager.decide_offer(QuestManager.present_offer(instance.instance_id, quest_component.npc_id), "accept")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "bunga", 10))
	xp = Player_Global_Data.player_exp
	finish_dialogue_later(dialogue_component, true)
	await quest_component.interact()
	check(instance.status == QuestInstance.Status.COMPLETE and not instance.reward_claimed and Player_Global_Data.player_exp == xp, "Cancelled ready dialogue leaves rewards unclaimed")
	definition = custom("test_dialogue_success", [objective("dialogue", QuestObjectiveData.ObjectiveType.DIALOGUE_COMPLETED, "cancellation_npc")])
	var successful_dialogue := active(definition.quest_id)
	finish_dialogue_later(dialogue_component, false)
	await dialogue_component.start_direct_text("Verified dialogue completion", "cancellation_npc")
	check(successful_dialogue.status == QuestInstance.Status.COMPLETE, "Natural Dialogic timeline completion publishes exactly one completion event")
	# Journal and board show multi-objective progress, locked prerequisites and rewards.
	reset_state()
	for id in QuestManager.registry.quests.keys():
		if String(id).begins_with("test_"): QuestManager.registry.quests.erase(id)
	instance = active("quest_bakau_007")
	QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_dragonfly", 2))
	var ui: QuestCatalogue = load("res://scenes/ui/quest-ui/quest-catalogue.tscn").instantiate()
	box.add_child(ui)
	ui._select("quest_bakau_007")
	check(ui.get_node("%ObjectivesLabel").text.contains("Pepatung: 2 / 4") and ui._buttons.size() == 14, "Journal shows all quests and stable individual objective progress")
	ui._select("quest_bakau_010")
	check(ui.get_node("%StatusLabel").text == "Locked" and ui.get_node("%RewardsLabel").text.contains("6 × Tech Scrap"), "Journal shows locked prerequisites and exact reward preview")
	ui.size = Vector2(800, 600)
	await frames()
	var detail: ScrollContainer = ui.get_node("Margin/Layout/Columns/DetailScroll")
	check(detail.get_child(0).size.x <= detail.size.x and detail.size.x > 0, "Quest details wrap inside the available width")
	box.free()
	QuestManager._save_timer.stop()
	QuestManager.persistence_enabled = false
	for path in ["user://quest-regression-v2.json", "user://quest-regression-v2.json.tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	completed = true
