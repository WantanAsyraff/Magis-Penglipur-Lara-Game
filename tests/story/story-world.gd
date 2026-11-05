extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("STORY_WORLD: " + label)
func _ready() -> void:
 await get_tree().process_frame
 var old_ready := SaveManager.session_ready
 SaveManager.session_ready = true
 StoryDirector._on_restored()
 var condition := StoryFlagCondition.new()
 condition.flag_definition = StoryDirector.registry.get_flag_definition(&"story.prologue.spm_completed")
 condition.expected_value = true
 var component := StoryConditionComponent.new()
 component.conditions.append(condition)
 add_child(component)
 await get_tree().process_frame
 check(not component.is_satisfied(), "unsatisfied fact is false")
 var portal: Variant = load("res://scenes/transitioners/zone-portal/zone-portal.gd").new()
 portal.entry_conditions.append(condition)
 check(not portal.story_unlocked(), "portal locked")
 var floor := ElevatorFloor.new()
 floor.story_conditions.append(condition)
 check(not floor.is_accessible(), "elevator floor locked")
 var room := RoomQuestManager.new()
 var spawn_rule := StoryNPCSpawnRule.new()
 spawn_rule.npc_id = "test_npc"
 spawn_rule.conditions.append(condition)
 room.story_spawn_rules.append(spawn_rule)
 check(not room._story_allows("test_npc"), "story-gated NPC spawn waits for milestone")
 var cutscene := StoryCutsceneTrigger.new()
 cutscene.sequence = load("res://data/story/after-final-paper.tres")
 cutscene.condition_component = component
 add_child(cutscene)
 check(not cutscene.try_play(), "cutscene condition blocks playback")
 var missing_item := StoryItemCondition.new()
 check(not StoryDirector.evaluate_condition(missing_item), "invalid item condition fails closed")
 var missing_spell := StorySpellCondition.new()
 check(not StoryDirector.evaluate_condition(missing_spell), "invalid spell condition fails closed")
 var resolver := StoryDialogueResolver.new()
 var low := StoryDialogueVariant.new()
 low.variant_id = &"test.low"
 low.direct_text = "TEST ONLY"
 low.priority = 1
 var high := StoryDialogueVariant.new()
 high.variant_id = &"test.high"
 high.direct_text = "TEST ONLY"
 high.priority = 9
 high.conditions.append(condition)
 high.once_only = true
 resolver.variants.append(low)
 resolver.variants.append(high)
 add_child(resolver)
 check(resolver.resolve_dialogue() == low, "fallback variant before fact")
 var actor := Node2D.new()
 add_child(actor)
 var presence := StoryPresenceComponent.new()
 presence.actor = actor
 presence.condition_component = component
 actor.add_child(presence)
 check(not actor.visible, "NPC presence hidden before milestone")
 var visual := Node2D.new()
 add_child(visual)
 var actuator := InteractionActuator.new()
 add_child(actuator)
 var world_state := StoryWorldStateComponent.new()
 world_state.condition_component = component
 world_state.visual_target = visual
 world_state.actuator = actuator
 world_state.actuator_port = EnvironmentLink.Port.ENABLE
 add_child(world_state)
 check(not visual.visible, "world visual hidden before milestone")
 check(not actuator.enabled, "environment actuator initially disabled")
 check(QuestManager.set_world_flag("story.prologue.spm_completed", true), "authoritative fact write")
 await get_tree().process_frame
 await get_tree().process_frame
 check(component.is_satisfied(), "condition refreshed")
 check(actor.visible, "NPC presence shown after milestone")
 check(visual.visible, "world visual shown after milestone")
 check(actuator.enabled, "story input reaches existing actuator")
 check(portal.story_unlocked(), "portal unlocked")
 check(floor.is_accessible(), "elevator floor unlocked")
 check(room._story_allows("test_npc"), "story-gated NPC spawn becomes eligible")
 QuestManager.set_world_flag(CutsceneFlow.flag_for(cutscene.sequence), true)
 check(not cutscene.try_play(), "completed cutscene does not replay")
 check(resolver.resolve_dialogue() == high, "higher priority dialogue selected")
 check(StoryDirector.complete_dialogue("test.high"), "completion receipt recorded")
 check(StoryDirector.state.dialogue_receipts.has("test.high") and not QuestManager.world_flags.has("story_dialogue:test.high"), "dialogue receipt belongs to story save state")
 check(resolver.resolve_dialogue() == low, "once-only variant consumed")
 check(not StoryDirector.complete_dialogue("test.high"), "duplicate receipt rejected")
 var tied := StoryDialogueVariant.new()
 tied.variant_id = &"test.tie"
 tied.direct_text = "TEST ONLY"
 tied.priority = low.priority
 resolver.variants.append(tied)
 check(not resolver.validate_variants().is_empty(), "ambiguous dialogue priority warns author")
 resolver.variants.erase(tied)
 SaveManager.loading = true
 check(not portal.story_unlocked(), "portal rejects restoration")
 check(not floor.story_allows(), "elevator rejects restoration")
 SaveManager.loading = false
 QuestManager.world_flags.erase("story.prologue.spm_completed")
 QuestManager.world_flags.erase(CutsceneFlow.flag_for(cutscene.sequence))
 portal.free()
 room.free()
 component.queue_free()
 resolver.queue_free()
 actor.queue_free()
 visual.queue_free()
 world_state.queue_free()
 actuator.queue_free()
 cutscene.queue_free()
 SaveManager.session_ready = old_ready
 StoryDirector.state.clear()
 print("STORY_WORLD: %d checks, %d failures" % [checks, failures])
 get_tree().quit(failures)
