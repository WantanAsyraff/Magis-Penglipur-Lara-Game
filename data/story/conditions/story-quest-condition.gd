class_name StoryQuestCondition extends StoryCondition
enum RequiredStatus { OFFERED, ACTIVE, OBJECTIVES_COMPLETE, HANDED_IN }
@export var quest_id: String
@export var required_status: RequiredStatus = RequiredStatus.HANDED_IN
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Unknown quest: " + quest_id]) if quest_id.is_empty() or not QuestManager.registry.quests.has(quest_id) else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
 if not validate(context.registry).is_empty(): return false
 var actual := context.quest_status(quest_id)
 match required_status:
  RequiredStatus.OFFERED: return actual == QuestInstance.Status.AVAILABLE
  RequiredStatus.ACTIVE: return actual == QuestInstance.Status.ACTIVE
  RequiredStatus.OBJECTIVES_COMPLETE: return actual == QuestInstance.Status.COMPLETE
  RequiredStatus.HANDED_IN: return actual == QuestInstance.Status.HANDED_OFF
 return false
