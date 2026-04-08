class_name QuestData
extends Resource

enum QuestType { MAIN, SIDE, FACTION, DEFEAT, FETCH }
enum Faculty { NONE, PHYSICS, COMPUTER_SCIENCE, ENGINEERING, MEDICINE, LAW }

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var type: QuestType = QuestType.SIDE
@export var faculty: Faculty = Faculty.NONE
@export var despawn_after_seconds: float = 60.0

@export_group("Objectives")
@export var objectives: Array[QuestObjectiveData] = []

@export_group("Rewards")
@export var reward_xp: int = 0
@export var reward_currency: int = 0
@export var reward_items: Array[LootData] = []
@export_group("Chaining")
@export var prerequisite_quest_ids: Array[String] = []
@export var next_quest_id: String = ""
