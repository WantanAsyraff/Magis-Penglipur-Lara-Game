class_name QuestData
extends Resource

enum QuestType { MAIN, SIDE, FACTION, DEFEAT, FETCH }
enum Faculty { NONE, PHYSICS, COMPUTER_SCIENCE, ENGINEERING, MEDICINE, LAW }

@export var faculty: Faculty = Faculty.NONE
@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var type: QuestType = QuestType.SIDE
@export var objectives: Array[QuestObjectiveData] = []

# dialogue timeline keys (Dialogic)
@export var dialogue_offer: String = ""
@export var dialogue_incomplete: String = ""
@export var dialogue_complete: String = ""

# rewards
@export var reward_xp: int = 0
@export var reward_currency: int = 0
@export var reward_item_ids: Array[String] = []
@export var reward_item_quantities: Array[int] = []

# chaining
@export var prerequisite_quest_ids: Array[String] = []
@export var next_quest_id: String = ""

# spawn settings
@export var despawn_after_seconds: float = -1.0   # -1 = no timer
@export var max_concurrent: int = 1               # how many NPCs can hold this quest at once
