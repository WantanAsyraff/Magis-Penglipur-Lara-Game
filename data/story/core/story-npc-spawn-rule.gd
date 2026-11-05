class_name StoryNPCSpawnRule extends Resource
@export var npc_id: String = ""
@export var conditions: Array[StoryCondition] = []
func allows() -> bool:
	if npc_id.is_empty() or conditions.is_empty() or SaveManager.loading or not StoryDirector.is_ready(): return false
	for condition in conditions:
		if condition == null or not StoryDirector.evaluate_condition(condition): return false
	return true
