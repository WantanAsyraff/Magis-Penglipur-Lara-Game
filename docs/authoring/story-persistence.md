# Persisting story content

Use stable `arc_id`, `chapter_id`, `stage_id`, transition IDs, action IDs and registered choice IDs. StoryDirector owns the active narrative position. `StorySaveService` stores it in the existing campaign profile; no separate story file is created. For persistent booleans use `StoryFlagDefinition.scope = CAMPAIGN`, which delegates to QuestManager. For nonboolean persistent values use `scope = PERSISTENT_TYPED` with INTEGER, FLOAT or STRING; values are bounded and validated. SESSION and SCENE remain transient. Add choice definitions to StoryDatabase before recording them.

## Saving and Restoring a Branching Story Without Duplicating Rewards

1. Add a registered StoryChoiceData and two stable StoryChoiceOptionData entries.
2. Add manual transitions to the source stage, each with matching `required_choice_id` and `required_option_id`.
3. Give required state actions stable `action_id` values. Keep quest rewards in QuestRewardService.
4. On confirmed input call `StoryDirector.confirm_choice(choice, option_id)`. Cancellation calls nothing.
5. Let the existing SaveManager manual or coalesced autosave write the full campaign snapshot.
6. On load, SaveManager stages the `story` section, then restores stage, choices and receipts without executing any transition or action.
7. Confirm the story stage and receipt from `StoryDirector` after `SaveManager.restored`.
