class_name RequestStoryAutosaveAction extends StoryAction
func validate(_registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Autosave cannot be required before Phase 3 story persistence"]) if required else PackedStringArray()
func execute(_context: StoryActionContext) -> Result:
 return Result.DEFERRED
