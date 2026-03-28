# RoomQuestManager.gd
extends Node2D
class_name RoomQuestManager

@export_group("Room Settings")
@export var room_id: String = ""
@export var max_npcs: int = 5
@export var room_faculty: QuestData.Faculty = QuestData.Faculty.NONE

@export_group("NPC Directory")
@export var npc_directory: Dictionary[String, PackedScene] = {}

var active_npcs: Array[Node2D] = []
var quests_completed_in_room: int = 0
var completion_threshold: int = 0

func _ready() -> void:
	completion_threshold = randi_range(2, 4)
	QuestManager.quest_handed_off.connect(_on_quest_handed_off)
	
	await get_tree().process_frame 
	spawn_npc("professor_ali")

func spawn_npc(npc_id_to_spawn: String) -> void:
	if active_npcs.size() >= max_npcs: return

	if not npc_directory.has(npc_id_to_spawn):
		push_error("[RoomManager] NPC ID '%s' not found!" % npc_id_to_spawn)
		return

	var npc_scene: PackedScene = npc_directory[npc_id_to_spawn]
	var npc_instance = npc_scene.instantiate()
	add_child(npc_instance)
	active_npcs.append(npc_instance)
	
	npc_instance.position = Vector2(randf_range(-100, 100), randf_range(-50, 50))
	
	var q_comp = npc_instance.find_child("QuestNPCComponent") as QuestNPCComponent
	if q_comp:
		q_comp.faculty = room_faculty
		q_comp.npc_id = npc_id_to_spawn 
		
		# CRITICAL: Now that the ID is set, tell the component to fetch its quest
		q_comp.setup_quest()
		
		q_comp.despawned.connect(func(): active_npcs.erase(npc_instance))

func _on_quest_handed_off(instance: QuestInstance) -> void:
	var was_our_npc = active_npcs.any(func(n): 
		var comp = n.find_child("QuestNPCComponent")
		return comp and comp.npc_id == instance.assigned_npc_id
	)
	
	if was_our_npc:
		quests_completed_in_room += 1
		if quests_completed_in_room >= completion_threshold:
			_clear_and_reset_room()

func _clear_and_reset_room() -> void:
	var to_clear = active_npcs.duplicate()
	for npc in to_clear:
		if is_instance_valid(npc): npc.queue_free()
	active_npcs.clear()
	quests_completed_in_room = 0
