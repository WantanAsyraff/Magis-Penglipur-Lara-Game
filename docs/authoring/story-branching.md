# Branching story authoring

## Creating a Branching Story Transition Without Writing GDScript

1. Create a StoryChoiceData Resource with a stable `choice_id`, prompt, and two StoryChoiceOptionData entries with distinct `option_id` values.
2. Add optional StoryCondition Resources to each option.
3. Add two manual StoryTransitionData Resources to the source stage. Give each a distinct `transition_id` and target stage.
4. Set each transition's `required_choice_id` and `required_option_id` to the corresponding choice and option IDs.
5. Present the options in a future Phase 4 dialogue or UI adapter. On explicit confirmation, call `StoryDirector.confirm_choice(choice, option_id)`; cancellation calls nothing.
6. Inspect `get_recorded_choice` and `get_diagnostics()` in a test session. Recorded choices and transition receipts are stored in the campaign story section after a successful save.

A choice cannot be silently selected by a transition action or by dialogue ending. Re-selection is rejected in Phase 2.
