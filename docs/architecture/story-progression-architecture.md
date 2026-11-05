# Story progression foundation

Phase 1 defines the authored graph in `data/story/definitions/story-database.tres`. `StoryRegistry` indexes stable arc, chapter, stage and flag IDs; duplicate or invalid IDs fail validation. `StoryDirector` is the single runtime coordinator. `StoryState` holds transient position and values. `StoryContext` exposes bounded read-only queries to conditions. Use `StoryConditionEvaluator.evaluate()` for bounded, cycle-safe evaluation.

QuestManager retains ownership of quests, rewards, receipts and boolean world flags. Persistent story flag writes call `QuestManager.set_world_flag`; its new `world_flag_changed` signal observes external writes without a second gameplay event. CutsceneFlow retains playback and writes `story_sequence:<id>` completion flags. SaveManager retains the Save V1 transaction. StoryDirector reacts only to `SaveManager.restored`, after commit; failed restores leave it unchanged.

Phase 3 stores current chapter, stage, typed persistent variables, choices and receipts in the existing Save V1 campaign snapshot. Old saves without a story section derive conservative defaults from confirmed cutscene facts. No separate story save file is used. See [story save architecture](story-save-architecture.md).
