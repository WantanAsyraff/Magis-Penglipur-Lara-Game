class_name StoryAnyCondition extends StoryCondition
@export var conditions: Array[StoryCondition] = []
func evaluate(context: StoryContext) -> bool:
 if conditions.is_empty(): return false
 for child in conditions:
  if StoryConditionEvaluator.evaluate(child, context): return true
 return false
