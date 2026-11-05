# Conditional events and cutscenes

QuestWorldEvent accepts optional `story_conditions` and a stable `trigger_id`. A player must genuinely enter its Area2D before it publishes the configured GameplayEvent. QuestManager retains receipt validation. Use StoryCutsceneTrigger with an existing CutsceneSequence and optional StoryConditionComponent. It delegates playback to CutsceneFlow and checks the canonical completion flag before starting.

An Area2D entrance publishes `LOCATION_REACHED` only. Spell casts, dialogue completions, quest completions and object interactions must be published by their actual gameplay owner after success. `StoryCutsceneTrigger.trigger_on_ready` retries after story changes and successful save restoration; `try_play()` can also be called by an authored interaction.

## Trigger a Cutscene Only Once

1. Add `StoryCutsceneTrigger` to the scene and assign an existing `CutsceneSequence` to `sequence`. Set `cutscene_owner` if the parent is not the owner.
2. Add an optional `StoryConditionComponent` and assign it to `condition_component`. Select `trigger_on_ready` for an automatic attempt, or call `try_play()` only after an actual authored interaction.
3. Run before and after the condition becomes true. Natural completion and a permitted skip both record `story_sequence:<sequence_id>` through CutsceneFlow; interruption does not.
4. Reload the campaign or reenter the scene. The canonical completion flag blocks replay. The production subway scene uses the existing `after-final-paper.tres` through this trigger.

The authored `data/story/definitions/conditions/intro-completed.tres` and `after-exam-completed.tres` demonstrate read-only completion conditions.
