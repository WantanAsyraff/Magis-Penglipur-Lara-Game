class_name StoryChapterCondition extends StoryCondition
@export var chapter_id: StringName
@export var equal: bool = true
func validate(registry: StoryRegistry) -> PackedStringArray:
 return PackedStringArray(["Unknown chapter: " + String(chapter_id)]) if registry.get_chapter(chapter_id) == null else PackedStringArray()
func evaluate(context: StoryContext) -> bool:
 return validate(context.registry).is_empty() and context.state.lifecycle == StoryState.Lifecycle.READY and (context.chapter_id() == chapter_id) == equal
