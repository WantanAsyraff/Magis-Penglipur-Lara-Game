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

@export var spawn_validator: NPCSpawnValidator
@export var safe_spawn_markers: Array[NodePath] = []
@export var access_markers: Array[NodePath] = []
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
	
	_spawn_after_physics()

# -------------------------
# SPAWN LOGIC
# -------------------------
func _spawn_after_physics() -> void:
	# physics_frame is emitted BEFORE the physics step. Wait for its completion
	# so TileMapLayer's initial collision updates have reached PhysicsServer2D.
	await get_tree().physics_frame
	await get_tree().process_frame
	_spawn_random_npcs()
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
	active_npcs = active_npcs.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	if not SpellExecutor.is_authoritative(self) or active_npcs.size() >= max_npcs: return
	if spawn_validator == null:
		push_warning("Room %s has no authored NPC placement policy; skipping unsafe spawn." % room_id)
		return
	var markers: Array[Vector2] = []
	var access: Array[Vector2] = []
	var others: Array[Vector2] = []
	for path in safe_spawn_markers:
		var marker := get_node_or_null(path) as Marker2D
		if marker: markers.append(marker.global_position)
	for path in access_markers:
		var marker := get_node_or_null(path) as Marker2D
		if marker: access.append(marker.global_position)
	for npc in get_tree().get_nodes_in_group("quest_npc"):
		if not npc.is_queued_for_deletion(): others.append(npc.global_position)
	var placement := spawn_validator.choose(get_world_2d().direct_space_state, global_position, markers, access, others)
	if placement.is_empty():
		push_warning("Room %s: no accessible NPC position after bounded validation; skipped %s." % [room_id, npc_id_to_spawn])
		return
	var npc: CharacterBody2D = npc_directory[npc_id_to_spawn].instantiate()
	var component := npc.find_child("QuestNPCComponent") as QuestNPCComponent
	if component:
		component.faculty = room_faculty
		component.npc_id = npc_id_to_spawn
	npc.position = to_local(placement.position)
	npc.add_to_group("quest_npc")
	add_child(npc)
	active_npcs.append(npc)
	Player_Global_Data.register_npc(npc_id_to_spawn)
	var wander := npc.find_child("WanderComponent") as WanderComponent
	if wander:
		wander.validator = spawn_validator
		wander.region = Rect2(global_position + spawn_validator.allowed_region.position, spawn_validator.allowed_region.size)
		wander.set_origin(npc.global_position)
	if component:
		component.setup_quest()
		component.despawned.connect(func():
			active_npcs.erase(npc)
			_replenish.call_deferred())

func _replenish() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	_spawn_random_npcs()

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
			if q_comp._busy: continue
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
