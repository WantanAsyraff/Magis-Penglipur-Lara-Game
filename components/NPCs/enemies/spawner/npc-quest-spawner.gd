# RoomQuestManager.gd
extends Node2D
class_name RoomQuestManager
@export_group("Room Settings")
@export var room_id: String = ""
@export var max_npcs: int = 5
@export var room_faculty: QuestData.Faculty = QuestData.Faculty.NONE
@export_group("Spawn Settings")
@export var npcs_to_spawn: int = 3
@export_group("NPC Directory")
@export var npc_directory: Dictionary[String, PackedScene] = {}

var active_npcs: Array[Node2D] = []
var quests_completed_in_room: int = 0
var completion_threshold: int = 0

func _ready() -> void:
	completion_threshold = randi_range(2, 4)
	QuestManager.quest_handed_off.connect(_on_quest_handed_off)
	print("[RoomQuestManager:%s] Ready — threshold: %d, directory keys: %s" % [room_id, completion_threshold, npc_directory.keys()])
	await get_tree().process_frame
	_spawn_random_npcs()

func _spawn_random_npcs() -> void:
	if npc_directory.is_empty():
		push_error("[RoomQuestManager:%s] npc_directory is empty!" % room_id)
		return
	var pool = npc_directory.keys().duplicate()
	pool.shuffle()
	var count = mini(npcs_to_spawn, pool.size())
	print("[RoomQuestManager:%s] Spawning %d NPC(s) from pool %s" % [room_id, count, pool])
	for i in count:
		spawn_npc(pool[i])

func spawn_npc(npc_id_to_spawn: String) -> void:
	print("[RoomQuestManager:%s] spawn_npc() called with '%s'" % [room_id, npc_id_to_spawn])
	if active_npcs.size() >= max_npcs:
		print("[RoomQuestManager:%s] Blocked — at max_npcs (%d)" % [room_id, max_npcs])
		return
	var already_spawned = active_npcs.any(func(n):
		var comp = n.find_child("QuestNPCComponent")
		return comp and comp.npc_id == npc_id_to_spawn
	)
	if already_spawned:
		print("[RoomQuestManager:%s] Blocked — '%s' already active in this room" % [room_id, npc_id_to_spawn])
		return
	# Global registry check — don't spawn if active in another room
	if not Player_Global_Data.register_npc(npc_id_to_spawn):
		print("[RoomQuestManager:%s] Blocked — '%s' already active globally" % [room_id, npc_id_to_spawn])
		return
	if not npc_directory.has(npc_id_to_spawn):
		push_error("[RoomQuestManager:%s] NPC ID '%s' not found in directory! Keys: %s" % [room_id, npc_id_to_spawn, npc_directory.keys()])
		Player_Global_Data.unregister_npc(npc_id_to_spawn)
		return
	var npc_scene: PackedScene = npc_directory[npc_id_to_spawn]
	var npc_instance = npc_scene.instantiate()
	add_child(npc_instance)
	active_npcs.append(npc_instance)
	npc_instance.position = Vector2(randf_range(-100, 100), randf_range(-50, 50))
	print("[RoomQuestManager:%s] Spawned '%s' at %s" % [room_id, npc_id_to_spawn, npc_instance.position])
	var q_comp = npc_instance.find_child("QuestNPCComponent") as QuestNPCComponent
	if q_comp:
		q_comp.faculty = room_faculty
		q_comp.npc_id = npc_id_to_spawn
		print("[RoomQuestManager:%s] QuestNPCComponent found — setting npc_id '%s', faculty '%s'" % [room_id, npc_id_to_spawn, room_faculty])
		q_comp.setup_quest()
		q_comp.despawned.connect(func():
			print("[RoomQuestManager:%s] NPC '%s' despawned" % [room_id, npc_id_to_spawn])
			Player_Global_Data.unregister_npc(npc_id_to_spawn)
			active_npcs.erase(npc_instance)
		)
	else:
		print("[RoomQuestManager:%s] WARNING — no QuestNPCComponent found on '%s'" % [room_id, npc_id_to_spawn])
		Player_Global_Data.unregister_npc(npc_id_to_spawn)

func _on_quest_handed_off(instance: QuestInstance) -> void:
	print("[RoomQuestManager:%s] quest_handed_off received — npc_id: '%s'" % [room_id, instance.assigned_npc_id])
	var was_our_npc = active_npcs.any(func(n):
		var comp = n.find_child("QuestNPCComponent")
		return comp and comp.npc_id == instance.assigned_npc_id
	)
	if was_our_npc:
		quests_completed_in_room += 1
		print("[RoomQuestManager:%s] Quest completed in room — %d/%d" % [room_id, quests_completed_in_room, completion_threshold])
		if quests_completed_in_room >= completion_threshold:
			print("[RoomQuestManager:%s] Threshold reached — clearing room" % room_id)
			_clear_and_reset_room()
	else:
		print("[RoomQuestManager:%s] quest_handed_off was not our NPC, ignoring" % room_id)

func _clear_and_reset_room() -> void:
	print("[RoomQuestManager:%s] Clearing %d NPCs" % [room_id, active_npcs.size()])
	var to_clear = active_npcs.duplicate()
	for npc in to_clear:
		if not is_instance_valid(npc):
			continue
		# Don't despawn NPCs with active/ongoing quests
		var q_comp = npc.find_child("QuestNPCComponent") as QuestNPCComponent
		if q_comp and q_comp._instance:
			var status = q_comp._instance.status
			if status == QuestInstance.Status.ACTIVE:
				print("[RoomQuestManager:%s] Keeping '%s' — quest is ongoing" % [room_id, q_comp.npc_id])
				continue
		var npc_id = ""
		var comp = npc.find_child("QuestNPCComponent") as QuestNPCComponent
		if comp:
			npc_id = comp.npc_id
		npc.queue_free()
		if npc_id != "":
			Player_Global_Data.unregister_npc(npc_id)
	active_npcs = active_npcs.filter(func(n):
		return is_instance_valid(n)
	)
	quests_completed_in_room = 0
	_spawn_random_npcs()
