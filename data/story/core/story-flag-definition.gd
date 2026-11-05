class_name StoryFlagDefinition extends Resource
## Persistent flags are BOOLEAN only. Other values exist only for this runtime session.
enum ValueType { BOOLEAN, INTEGER, FLOAT, STRING }
enum Scope { CAMPAIGN, SESSION, SCENE, PERSISTENT_TYPED }
@export_group("Identity")
@export var flag_id: StringName
@export var display_name: String
@export_multiline var description: String
@export_group("Value")
@export var value_type: ValueType = ValueType.BOOLEAN
@export var scope: Scope = Scope.CAMPAIGN
@export var default_value: Variant = false
func valid_value(value: Variant) -> bool:
 match value_type:
  ValueType.BOOLEAN: return value is bool
  ValueType.INTEGER: return value is int and value >= -9007199254740991 and value <= 9007199254740991
  ValueType.FLOAT: return value is float and is_finite(value) and absf(value) <= 1000000000000.0
  ValueType.STRING: return value is String and value.length() <= 512
 return false
