extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("STORY: " + label)
func _ready() -> void:
 check(StoryDirector.registry.errors.is_empty(), "registered database valid")
 check(StoryDirector.registry.get_arc(&"main") != null, "arc lookup")
 check(StoryDirector.registry.get_chapter(&"prologue") != null, "chapter lookup")
 check(StoryDirector.registry.get_stage(&"prologue.spm_practical") != null, "stage lookup")
 check(StoryDirector.registry.get_stage(&"unknown") == null, "unknown stage")
 var duplicate := StoryDatabase.new()
 duplicate.arcs = [StoryDirector.database.arcs[0], StoryDirector.database.arcs[0]]
 check(not StoryRegistry.new(duplicate).errors.is_empty(), "duplicate arc rejected")
 var flag := StoryDirector.registry.get_flag_definition(&"story.prologue.spm_completed")
 check(flag != null and flag.valid_value(true), "registered boolean")
 check(not flag.valid_value(1), "wrong flag type")
 check(not StoryDirector.set_flag(&"unknown", true), "unknown mutation rejected")
 check(not StoryDirector.set_flag(flag.flag_id, true), "uninitialized mutation rejected")
 var state := StoryState.new()
 state.lifecycle = StoryState.Lifecycle.READY
 state.arc_id = &"main"
 state.chapter_id = &"prologue"
 state.stage_id = &"prologue.wake_up"
 var context := StoryContext.new(StoryDirector.registry, state)
 var stage := StoryStageCondition.new()
 stage.stage_id = &"prologue.wake_up"
 check(StoryConditionEvaluator.evaluate(stage, context), "stage equality")
 var chapter := StoryChapterCondition.new()
 chapter.chapter_id = &"prologue"
 check(StoryConditionEvaluator.evaluate(chapter, context), "chapter equality")
 var all := StoryAllCondition.new()
 all.conditions = [stage, chapter]
 check(StoryConditionEvaluator.evaluate(all, context), "all composition")
 var any := StoryAnyCondition.new()
 var false_stage := StoryStageCondition.new()
 false_stage.stage_id = &"prologue.after_exam"
 any.conditions = [false_stage, chapter]
 check(StoryConditionEvaluator.evaluate(any, context), "any composition")
 var negation := StoryNotCondition.new()
 negation.condition = false_stage
 check(StoryConditionEvaluator.evaluate(negation, context), "not composition")
 negation.condition = negation
 check(not StoryConditionEvaluator.evaluate(negation, context), "cycle rejected")
 var cutscene := StoryCutsceneCondition.new()
 cutscene.sequence_reference = load("res://data/story/kampung-intro.tres")
 check(StoryConditionEvaluator.evaluate(cutscene, context) == QuestManager.world_flags.get("story_sequence:prologue.kampung", false), "cutscene reads canonical flag")
 check(QuestManager.world_flags.is_empty(), "conditions do not mutate flags")
 var prior_ready := SaveManager.session_ready
 SaveManager.session_ready = true
 StoryDirector._on_restored()
 check(StoryDirector.is_ready() and StoryDirector.get_current_stage_id() == &"prologue.wake_up", "post-restore initialization")
 check(StoryDirector.set_flag(flag.flag_id, true), "persistent boolean delegated")
 check(QuestManager.world_flags.get(String(flag.flag_id), false) == true, "QuestManager owns persistent fact")
 check(not StoryDirector.set_flag(flag.flag_id, true), "unchanged write is silent")
 QuestManager.set_world_flag(String(flag.flag_id), false)
 check(StoryDirector.get_flag(flag.flag_id) == false, "external world-flag write observed")
 SaveManager.loading = true
 check(not StoryDirector.set_flag(flag.flag_id, true), "restore blocks mutation")
 SaveManager.loading = false
 QuestManager.world_flags.erase(String(flag.flag_id))
 SaveManager.session_ready = prior_ready
 StoryDirector.state.clear()
 print("STORY_FOUNDATION: %d checks, %d failures" % [checks, failures])
 get_tree().quit(failures)
