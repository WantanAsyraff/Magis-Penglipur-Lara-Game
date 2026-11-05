class_name StoryAction extends Resource
enum Result { SUCCESS, NO_CHANGE, DEFERRED, REJECTED, FAILED }
@export var required: bool = true
@export var action_id: StringName
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray()
func execute(_context: StoryActionContext) -> Result:
 return Result.REJECTED
