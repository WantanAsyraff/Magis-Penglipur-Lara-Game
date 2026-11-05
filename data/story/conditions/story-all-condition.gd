class_name StoryAllCondition extends StoryCondition
@export var conditions: Array[StoryCondition] = []
func evaluate(context: StoryContext) -> bool:
 if conditions.is_empty(): return false
 for child in conditions:
  if not StoryConditionEvaluator.evaluate(child, context): return false
 return true
