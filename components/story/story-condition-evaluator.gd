class_name StoryConditionEvaluator extends RefCounted
const MAX_DEPTH := 16
const MAX_NODES := 128
static var _active: Dictionary = {}
static var _count := 0
static func evaluate(condition: StoryCondition, context: StoryContext) -> bool:
 if condition == null or context == null or context.registry == null: return false
 var root := _active.is_empty()
 if root:
  _count = 0
  if not validate_graph(condition, context.registry): return false
 var id := condition.get_instance_id()
 if _active.has(id) or _active.size() >= MAX_DEPTH or _count >= MAX_NODES:
  if root: _active.clear()
  return false
 _active[id] = true
 _count += 1
 var result := condition.validate(context.registry).is_empty() and condition.evaluate(context)
 _active.erase(id)
 if root: _count = 0
 return result

static func validate_graph(condition: StoryCondition, registry: StoryRegistry) -> bool:
 return _validate_node(condition, registry, {}, 0, [0])
static func _validate_node(condition: StoryCondition, registry: StoryRegistry, path: Dictionary, depth: int, count: Array) -> bool:
 if condition == null or depth >= MAX_DEPTH or count[0] >= MAX_NODES: return false
 var id := condition.get_instance_id()
 if path.has(id) or not condition.validate(registry).is_empty(): return false
 path[id] = true
 count[0] += 1
 var children: Array = []
 if condition is StoryAllCondition or condition is StoryAnyCondition:
  children = condition.conditions
  if children.is_empty(): return false
 elif condition is StoryNotCondition:
  children = [condition.condition]
 for child in children:
  if not _validate_node(child, registry, path, depth + 1, count): return false
 path.erase(id)
 return true
