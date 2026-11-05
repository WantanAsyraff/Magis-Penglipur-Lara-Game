class_name StoryNotCondition extends StoryCondition
@export var condition: StoryCondition
func evaluate(context: StoryContext) -> bool:
 return condition != null and not StoryConditionEvaluator.evaluate(condition, context)
