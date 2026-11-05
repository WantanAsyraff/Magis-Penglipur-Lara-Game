class_name SetStoryVariableAction extends StoryAction
enum Operation { SET, INCREMENT, DECREMENT }
@export var variable_definition: StoryFlagDefinition
@export var operation: Operation = Operation.SET
@export var value: Variant = 0
func validate(registry: StoryRegistry) -> PackedStringArray:
 if variable_definition == null or registry.get_flag_definition(variable_definition.flag_id) != variable_definition: return PackedStringArray(["Unknown variable"])
 if variable_definition.scope == StoryFlagDefinition.Scope.CAMPAIGN: return PackedStringArray(["Persistent typed variables await Phase 3"])
 if not variable_definition.valid_value(value): return PackedStringArray(["Invalid variable value"])
 if operation != Operation.SET and variable_definition.value_type not in [StoryFlagDefinition.ValueType.INTEGER, StoryFlagDefinition.ValueType.FLOAT]: return PackedStringArray(["Arithmetic requires numeric variable"])
 return PackedStringArray()
func execute(context: StoryActionContext) -> Result:
 if not validate(context.registry).is_empty(): return Result.REJECTED
 var old: Variant = context.director.get_flag(variable_definition.flag_id)
 var result: Variant = value
 if operation == Operation.INCREMENT: result = old + value
 if operation == Operation.DECREMENT: result = old - value
 if not variable_definition.valid_value(result): return Result.FAILED
 if old == result: return Result.NO_CHANGE
 return Result.SUCCESS if context.director.set_flag(variable_definition.flag_id, result) else Result.FAILED
