@tool
class_name StoryCutsceneTrigger extends Node
@export var sequence: CutsceneSequence
@export var condition_component: StoryConditionComponent
@export var cutscene_owner: Node
@export var trigger_on_ready := false
var _playing := false
func _ready() -> void:
 if Engine.is_editor_hint(): return
 if cutscene_owner == null: cutscene_owner = get_parent()
 CutsceneFlow.sequence_finished.connect(_on_sequence_finished)
 if trigger_on_ready:
  SaveManager.restored.connect(_schedule_play)
  StoryDirector.story_state_changed.connect(_schedule_play)
  if condition_component: condition_component.conditions_became_satisfied.connect(_schedule_play)
  _schedule_play()
func _schedule_play() -> void:
 if is_inside_tree() and not SaveManager.loading: call_deferred("try_play")
func _on_sequence_finished(finished: CutsceneSequence, _outcome: int) -> void:
 if finished == sequence: _playing = false
func try_play() -> bool:
 if _playing or sequence == null or cutscene_owner == null or not is_instance_valid(cutscene_owner) or SaveManager.loading or not StoryDirector.is_ready(): return false
 if condition_component and not condition_component.is_satisfied(): return false
 if QuestManager.world_flags.get(CutsceneFlow.flag_for(sequence), false): return false
 _playing = CutsceneFlow.play(cutscene_owner, sequence)
 return _playing
func get_diagnostics() -> Dictionary:
 return {"sequence": sequence.sequence_id if sequence else "", "completed": sequence != null and QuestManager.world_flags.get(CutsceneFlow.flag_for(sequence), false), "eligible": sequence != null and not SaveManager.loading and StoryDirector.is_ready() and (condition_component == null or condition_component.is_satisfied())}
func _exit_tree() -> void:
 if _playing and CutsceneFlow.story_owner == cutscene_owner: CutsceneFlow.interrupt()
func _get_configuration_warnings() -> PackedStringArray:
 if sequence == null: return PackedStringArray(["Assign an existing CutsceneSequence Resource."])
 return sequence.validate()
