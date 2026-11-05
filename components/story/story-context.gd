class_name StoryContext extends RefCounted
## Bounded, read-only queries; no mutable service dictionaries are exposed.
var registry: StoryRegistry
var state: StoryState
func _init(r: StoryRegistry, s: StoryState) -> void:
 registry = r
 state = s
func arc_id() -> StringName: return state.arc_id if state.lifecycle == StoryState.Lifecycle.READY else &""
func chapter_id() -> StringName: return state.chapter_id if state.lifecycle == StoryState.Lifecycle.READY else &""
func stage_id() -> StringName: return state.stage_id if state.lifecycle == StoryState.Lifecycle.READY else &""
func flag_value(id: StringName) -> Variant:
 var definition := registry.get_flag_definition(id)
 if definition == null: return null
 if definition.scope == StoryFlagDefinition.Scope.CAMPAIGN:
  return QuestManager.world_flags.get(String(id), definition.default_value)
 if definition.scope == StoryFlagDefinition.Scope.PERSISTENT_TYPED:
  return state.read_transient(id, definition.default_value)
 return state.read_transient(id, definition.default_value)
func has_world_flag(id: String) -> bool: return QuestManager.world_flags.get(id, false) == true
func is_cutscene_complete(sequence: CutsceneSequence) -> bool:
 return sequence != null and sequence.validate().is_empty() and has_world_flag(CutsceneFlow.flag_for(sequence))
func quest_status(id: String) -> int:
 for instance in QuestManager._active_instances.values():
  if instance.owner_id == QuestManager.active_owner_id and instance.quest_data.quest_id == id: return instance.status
 return QuestInstance.Status.HANDED_OFF if QuestManager.is_quest_complete(id) else -1
