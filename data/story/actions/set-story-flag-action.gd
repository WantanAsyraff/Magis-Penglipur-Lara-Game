class_name SetStoryFlagAction extends StoryAction
@export var flag_definition: StoryFlagDefinition
@export var value: Variant = true
func validate(registry: StoryRegistry) -> PackedStringArray:
 if flag_definition == null or registry.get_flag_definition(flag_definition.flag_id) != flag_definition: return PackedStringArray(["Unregistered flag action"])
 if not flag_definition.valid_value(value): return PackedStringArray(["Flag action value type mismatch"])
 if required and flag_definition.scope == StoryFlagDefinition.Scope.CAMPAIGN: return PackedStringArray(["Persistent flag action cannot be required before Phase 3 transactions"])
 return PackedStringArray()
func execute(context: StoryActionContext) -> Result:
 if not validate(context.registry).is_empty(): return Result.REJECTED
 if context.director.get_flag(flag_definition.flag_id) == value: return Result.NO_CHANGE
 return Result.SUCCESS if context.director.set_flag(flag_definition.flag_id, value) else Result.FAILED
