extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("STORY_SAVE: " + label)
func _ready() -> void:
 var registry := StoryDirector.registry
 var defaults := StorySaveService.defaults(registry)
 check(not defaults.is_empty(), "authored defaults")
 check(StorySaveService.stage(defaults, registry) == defaults, "defaults stage")
 var prior_story_v1 := defaults.duplicate(true)
 prior_story_v1.erase("completed_dialogues")
 check(StorySaveService.stage(prior_story_v1, registry).completed_dialogues.is_empty(), "older Story V1 save defaults dialogue receipts")
 var legacy := StorySaveService.stage(null, registry, {"world_flags": {"story_sequence:prologue.kampung": true}})
 check(legacy.active_stage_id == "prologue.leave_house", "legacy intro derives only confirmed stage")
 var invalid := defaults.duplicate(true)
 invalid.active_stage_id = "missing"
 check(StorySaveService.stage(invalid, registry).is_empty(), "unknown stage rejected")
 var migrations := StoryIdMigrations.new()
 migrations.stages = {"legacy.wake": "prologue.wake_up"}
 registry.database.migrations = migrations
 invalid = defaults.duplicate(true)
 invalid.active_stage_id = "legacy.wake"
 check(StorySaveService.stage(invalid, registry).active_stage_id == "prologue.wake_up", "reviewed stage alias migrates")
 registry.database.migrations = null
 invalid = defaults.duplicate(true)
 invalid.version = 2
 check(StorySaveService.stage(invalid, registry).is_empty(), "unsupported version rejected")
 invalid = defaults.duplicate(true)
 invalid.choices["unknown.choice"] = "option"
 check(StorySaveService.stage(invalid, registry).is_empty(), "unknown choice rejected")
 invalid = defaults.duplicate(true)
 invalid.variables["unknown.variable"] = 3
 check(StorySaveService.stage(invalid, registry).is_empty(), "unknown variable rejected")
 invalid = defaults.duplicate(true)
 invalid.completed_transitions = ["main:prologue:unknown.transition"]
 check(StorySaveService.stage(invalid, registry).is_empty(), "unknown transition receipt rejected")
 invalid = defaults.duplicate(true)
 invalid.completed_actions = ["main:prologue:unknown.transition:unknown.action"]
 check(StorySaveService.stage(invalid, registry).is_empty(), "unknown action receipt rejected")
 invalid = defaults.duplicate(true)
 invalid.objective_text = "x".repeat(1025)
 check(StorySaveService.stage(invalid, registry).is_empty(), "oversized objective rejected")
 var state := StoryState.new()
 StorySaveService.apply(state, defaults)
 check(state.stage_id == &"prologue.wake_up", "stage restored")
 state.dialogue_receipts["test.once"] = true
 var saved := StorySaveService.encode(state, registry)
 check(StorySaveService.stage(saved, registry) == saved, "encoded state stages")
 check(saved.completed_dialogues == ["test.once"], "dialogue receipt encoded")
 migrations = StoryIdMigrations.new()
 migrations.dialogues = {"test.old": "test.once"}
 registry.database.migrations = migrations
 var renamed_dialogue := saved.duplicate(true)
 renamed_dialogue.completed_dialogues = ["test.old"]
 check(StorySaveService.stage(renamed_dialogue, registry).completed_dialogues == ["test.once"], "reviewed dialogue alias migrates")
 registry.database.migrations = null
 var invalid_dialogues := saved.duplicate(true)
 invalid_dialogues.completed_dialogues = ["test.once", "test.once"]
 check(StorySaveService.stage(invalid_dialogues, registry).is_empty(), "duplicate dialogue receipt rejected")
 var prior := StorySaveService.capture_runtime(state)
 state.stage_id = &"prologue.after_exam"
 StorySaveService.restore_runtime(state, prior)
 check(state.stage_id == &"prologue.wake_up", "rollback restores stage")
 var variable := StoryFlagDefinition.new()
 variable.flag_id = &"story.prologue.score"
 variable.value_type = StoryFlagDefinition.ValueType.INTEGER
 variable.scope = StoryFlagDefinition.Scope.PERSISTENT_TYPED
 variable.default_value = 0
 registry.flags[String(variable.flag_id)] = variable
 state.write_transient(variable.flag_id, 7)
 saved = StorySaveService.encode(state, registry)
 check(saved.variables.get("story.prologue.score") == 7 and not StorySaveService.stage(saved, registry).is_empty(), "typed variable encoded")
 invalid = saved.duplicate(true)
 invalid.variables["story.prologue.score"] = "7"
 check(StorySaveService.stage(invalid, registry).is_empty(), "wrong variable type rejected")
 registry.flags.erase(String(variable.flag_id))
 print("STORY_SAVE: %d checks, %d failures" % [checks, failures])
 get_tree().quit(failures)
