class_name QuestData
extends Resource

enum QuestType { MAIN, SIDE, FACTION, DEFEAT, FETCH }
enum Faculty { NONE, PHYSICS, COMPUTER_SCIENCE, ENGINEERING, MEDICINE, LAW, TECHNOLOGY_SCIENCE }

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

@export_group("Quest Pipeline V2")
@export var region_id: StringName = &"flac"
@export var pool_id: StringName = &""
@export var tags: Array[StringName] = []
@export var repeatable: bool = false
@export var hand_in_npc_id: String = ""
@export var auto_accept_next: bool = false
@export var expires_after_seconds: float = 0
@export var objective_groups: Array[QuestObjectiveGroup] = []
@export var reward_spells: Array[SpellData] = []
@export var reward_flags: Dictionary[StringName, bool] = {}
@export_multiline var dialogue_offer: String = ""
@export_multiline var dialogue_incomplete: String = ""
@export_multiline var dialogue_complete: String = ""

@export_multiline var dialogue_accepted: String = ""
@export_multiline var dialogue_declined: String = ""
