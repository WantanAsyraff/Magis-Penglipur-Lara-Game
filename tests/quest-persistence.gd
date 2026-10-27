extends Node
const SAVE = "user://quest-restart-regression-v2.json"
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func _ready() -> void:
	await get_tree().process_frame
	QuestManager._save_timer.stop()
	QuestManager.save_path = SAVE
	if "--write-quest-save" in OS.get_cmdline_user_args():
		Inventory_Manager.reset()
		Player_Global_Data.completed_quests.clear()
		Player_Global_Data.player_exp = 0
		var first := QuestManager.offer_quest("quest_bakau_001", "bakau_field_researcher")
		check(first != null and QuestManager.decide_offer(QuestManager.present_offer(first.instance_id, "bakau_field_researcher"), "accept"), "Restart fixture accepts actual quest")
		QuestManager.publish(GameplayEvent.new(GameplayEvent.Type.ENEMY_DEFEATED, "enemy_mangroove_snakehead_murrel", 8))
		QuestManager.persistence_enabled = true
		check(QuestManager.try_hand_off(first.instance_id, "bakau_field_researcher"), "Restart fixture commits reward and claim")
		var second := QuestManager.offer_quest("quest_bakau_002", "bakau_field_researcher")
		check(second != null and QuestManager.decide_offer(QuestManager.present_offer(second.instance_id, "bakau_field_researcher"), "accept"), "Restart fixture unlocks dependent quest")
		Inventory_Manager.pickup(QuestManager.registry.items.drop_001, 2, "restart-pickup")
		QuestManager.select_quest(second.instance_id)
		QuestManager.mark_conversation_read("bakau_field_researcher")
		check(QuestManager.save_game(), "Restart fixture saves active progress and inventory")
	else:
		check(QuestManager.load_game(), "Fresh process loads saved state")
		check(Player_Global_Data.player_exp == 120 and Inventory_Manager.get_item_quantity("craft_cons_001") == 2, "Fresh process restores exact reward quantities")
		var selected := QuestManager.get_instance(QuestManager.selected_instance_id)
		check(selected != null and selected.quest_data.quest_id == "quest_bakau_002" and selected.objective_progress.values()[0] == 2, "Fresh process restores selected quest and collection progress")
		check(Inventory_Manager.pickup(QuestManager.registry.items.drop_001, 2, "restart-pickup") == 0, "Fresh process rejects replayed acquisition")
		var claimed: QuestInstance
		for instance in QuestManager._active_instances.values():
			if instance.quest_data.quest_id == "quest_bakau_001": claimed = instance
		check(claimed != null and claimed.reward_claimed and not QuestManager.try_hand_off(claimed.instance_id, "bakau_field_researcher"), "Fresh process rejects repeated reward claim")
		var contact: QuestConversation = QuestManager.conversations.contacts.get("bakau_field_researcher")
		check(contact != null and contact.entries.filter(func(e): return e.event_type == "PLAYER_ACCEPTED").size() == 2, "Fresh process restores explicit decisions for both quests")
		check(contact != null and not contact.unread(), "Fresh process restores conversation read state")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	QuestManager.persistence_enabled = false
	QuestManager._save_timer.stop()
	print("QUEST_PERSISTENCE: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
