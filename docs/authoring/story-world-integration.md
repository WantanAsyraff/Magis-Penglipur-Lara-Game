# Story world integration

Add `StoryConditionComponent` to a scene object and assign typed StoryCondition Resources. It caches its result and refreshes on StoryDirector, quest, inventory and player progression signals. Empty or invalid conditions fail closed. Add `StoryWorldStateComponent` to show an optional CanvasItem, enable interaction, play an authored AnimationPlayer animation or send a value to an existing InteractionActuator port. Device behavior remains in InteractionActuator and EnvironmentDevice. On restoration, the adapter recalculates after SaveManager.restored.

Available conditions also include `StorySubjectCondition` (`subject_id`), `StorySpellCondition` (`spell`), `StoryItemCondition` (`item`, `minimum_quantity`) and `StoryChoiceCondition` (`choice`, `option_id`). They query the existing academic, spell, inventory and StoryDirector state. The world adapter's `respect_persistent_device_state` keeps an already activated or broken persistent device under WorldPersistence authority.

## Unlock a Door After Completing the SPM Practical

1. In a test scene, create `StoryFlagCondition` and assign the registered `story.prologue.spm_completed` StoryFlagDefinition; set `expected_value = true`.
2. On a ZonePortal, add that Resource to `entry_conditions`, set `locked_hint`, and retain its existing `next_scene_id` and spawn marker. To drive an EnvironmentDevice gate instead, add `StoryConditionComponent` and `StoryWorldStateComponent`, assign the condition and the device's existing `Actuator`, then select `actuator_port = UNLOCK`.
3. Run the scene before and after a legitimate completion publisher calls `StoryDirector.set_flag(&"story.prologue.spm_completed", true)`. The portal rechecks on interaction; the gate uses its existing actuator computation and collision.

The current production practical has no verified passed fact, so this recipe must use a test fixture until the exam publishes one. Entering the lab is not evidence of passing. Do not add the gate to the mandatory production route yet.

## Make an NPC Appear After a Story Milestone

1. Add `StoryConditionComponent` beneath the NPC and assign a registered `StoryFlagCondition`, `StoryStageCondition`, or `StoryQuestCondition` to `conditions`.
2. Add `StoryPresenceComponent` beneath the same NPC. Set `actor` to the NPC and `condition_component` to the first child.
3. Configure `hide_when_unsatisfied`, `disable_interaction_when_unsatisfied` and `pause_ai_when_unsatisfied` in the Inspector.
4. Run before and after the authoritative milestone. The NPC instance, quest component and identity remain intact while hidden; a change during dialogue waits until that dialogue ends.

For a RoomQuestManager NPC, create a `StoryNPCSpawnRule` in `story_spawn_rules` with the NPC directory ID and conditions. The room evaluates that rule before spawning and uses its existing `NPCSpawnValidator` and safe markers. A condition change schedules another bounded fill attempt. Once spawned, the NPC gets presence components and stays safely hidden if the condition later becomes false; it is not destroyed during an active quest.

## Gate an elevator floor

Open an existing `ElevatorFloor` Resource, add one or more StoryCondition Resources to `story_conditions`, and write a `locked_hint`. Keep `scene_id` as an existing Scene_Registry identity. The floor remains blocked if its original `locked` value is true; story conditions are an additional requirement. The elevator rechecks the selected floor when the button is pressed, including when `use_locking` is disabled for legacy floors.

## Connect a world mechanism

Add `StoryConditionComponent` and `StoryWorldStateComponent` beneath a world object. Assign `condition_component`, the existing `InteractionActuator` to `actuator`, and select an authored `actuator_port` such as ENABLE, POWER, INPUT or UNLOCK. The adapter sends a boolean into the existing device logic. Optional `visual_target`, `interaction_target`, `animation_player`, `animation_when_satisfied` and `animation_when_unsatisfied` drive presentation. Persistent broken or activated devices retain their saved WorldPersistence state when `respect_persistent_device_state` is enabled.
