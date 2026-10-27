# RoomQuestManager.gd
extends Node2D
class_name RoomQuestManager

@export_group("Room Settings")
@export var room_id: String = ""
@export var max_npcs: int = 5
@export var room_faculty: QuestData.Faculty = QuestData.Faculty.NONE

@export_group("Spawn Settings")
@export var npcs_to_spawn: int = 3 # Target number of NPCs to maintain

@export_group("NPC Directory")
@export var npc_directory: Dictionary[String, PackedScene] = {}

var active_npcs: Array[Node2D] = []
var quests_completed_in_room: int = 0
var completion_threshold: int = 0

# -------------------------
# READY
# -------------------------
func _ready() -> void:
	completion_threshold = randi_range(2, 4)
	
	if QuestManager.is_connected("quest_handed_off", _on_quest_handed_off):
		QuestManager.quest_handed_off.disconnect(_on_quest_handed_off)
	QuestManager.quest_handed_off.connect(_on_quest_handed_off)
	
	print("[RoomQuestManager:%s] Ready — threshold: %d" % [room_id, completion_threshold])
	
	_spawn_random_npcs()

# -------------------------
# SPAWN LOGIC
# -------------------------
func _spawn_random_npcs() -> void:
	if npc_directory.is_empty():
		return

	var ids_currently_in_room: Array[String] = []
	for npc in active_npcs:
		if is_instance_valid(npc):
			var comp = npc.find_child("QuestNPCComponent") as QuestNPCComponent
			if comp: ids_currently_in_room.append(comp.npc_id)

	var pool := npc_directory.keys().filter(func(id): return not ids_currently_in_room.has(id))
	pool.shuffle()

	var current_count = active_npcs.size()
	var target_to_fill = npcs_to_spawn - current_count
	var space_available = max_npcs - current_count
	var num_to_spawn = clampi(target_to_fill, 0, space_available)
	num_to_spawn = mini(num_to_spawn, pool.size())

	for i in num_to_spawn:
		spawn_npc(pool[i])

func spawn_npc(npc_id_to_spawn: String) -> void:
	if active_npcs.size() >= max_npcs:
		return

	# FIX: Instead of calling is_npc_registered, check the array directly
	var is_registered = Player_Global_Data.active_npc_ids.has(npc_id_to_spawn)
	
	# If not registered, register them using the existing function
	if not is_registered:
		Player_Global_Data.register_npc(npc_id_to_spawn)

	var npc_scene: PackedScene = npc_directory[npc_id_to_spawn]
	var npc_instance: Node2D = npc_scene.instantiate()
	
	var prepared := npc_instance.find_child("QuestNPCComponent") as QuestNPCComponent
	if prepared:
		prepared.faculty = room_faculty
		prepared.npc_id = npc_id_to_spawn
	npc_instance.position = Vector2(randf_range(-100, 100), randf_range(-50, 50))
	add_child(npc_instance)
	active_npcs.append(npc_instance)
	
	npc_instance.position = Vector2(randf_range(-100, 100), randf_range(-50, 50))

	var q_comp := npc_instance.find_child("QuestNPCComponent") as QuestNPCComponent
	if q_comp:
		q_comp.faculty = room_faculty
		q_comp.npc_id = npc_id_to_spawn
		q_comp.setup_quest() 
		
		q_comp.despawned.connect(func() -> void:
			if active_npcs.has(npc_instance):
				active_npcs.erase(npc_instance)
			Player_Global_Data.unregister_npc(npc_id_to_spawn)
		)

# -------------------------
# ROOM PROGRESSION
# -------------------------
func _on_quest_handed_off(instance: QuestInstance) -> void:
	var is_our_npc = active_npcs.any(func(n):
		if not is_instance_valid(n): return false
		var comp = n.find_child("QuestNPCComponent")
		return comp != null and comp.npc_id == instance.assigned_npc_id
	)

	if not is_our_npc:
		return

	quests_completed_in_room += 1
	if quests_completed_in_room >= completion_threshold:
		_clear_and_reset_room()

# -------------------------
# CLEAR AND RESET
# -------------------------
func _clear_and_reset_room() -> void:
	var to_remove: Array[Node2D] = []
	
	for npc in active_npcs:
		if not is_instance_valid(npc): continue
		
		var q_comp := npc.find_child("QuestNPCComponent") as QuestNPCComponent
		if q_comp:
			if q_comp._instance and q_comp._instance.status in [QuestInstance.Status.ACTIVE, QuestInstance.Status.COMPLETE]:
				continue
			to_remove.append(npc)

	for npc in to_remove:
		active_npcs.erase(npc)
		npc.queue_free()

	quests_completed_in_room = 0
	completion_threshold = randi_range(2, 4)

	await get_tree().process_frame
	_spawn_random_npcs()
