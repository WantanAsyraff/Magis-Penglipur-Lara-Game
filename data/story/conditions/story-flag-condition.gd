class_name StoryFlagCondition extends StoryCondition
enum Comparison { EQUAL, NOT_EQUAL, GREATER, LESS }
@export var flag_definition: StoryFlagDefinition
@export var comparison: Comparison = Comparison.EQUAL
@export var expected_value: Variant = true
func validate(registry: StoryRegistry) -> PackedStringArray:
 var errors := PackedStringArray()
 if flag_definition == null or registry.get_flag_definition(flag_definition.flag_id) != flag_definition: errors.append("Flag condition has unregistered definition")
 elif not flag_definition.valid_value(expected_value): errors.append("Flag condition expected value has wrong type")
 elif comparison in [Comparison.GREATER, Comparison.LESS] and flag_definition.value_type not in [StoryFlagDefinition.ValueType.INTEGER, StoryFlagDefinition.ValueType.FLOAT]: errors.append("Numeric comparison requires numeric flag")
 return errors
func evaluate(context: StoryContext) -> bool:
 if not validate(context.registry).is_empty(): return false
 var value: Variant = context.flag_value(flag_definition.flag_id)
 match comparison:
  Comparison.EQUAL: return value == expected_value
  Comparison.NOT_EQUAL: return value != expected_value
  Comparison.GREATER: return value > expected_value
  Comparison.LESS: return value < expected_value
 return false
