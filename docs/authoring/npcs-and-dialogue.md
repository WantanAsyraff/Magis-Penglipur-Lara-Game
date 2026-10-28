# NPCs, interaction and dialogue

## Schemas, scenes and identities

[NPCPresentation](../../data/npc/npc-presentation.gd) is the authored identity Resource. The reusable [npc.tscn](../../components/NPCs/npc.tscn) composes DetectionComponent, DialogicComponent, WanderComponent, QuestNPCComponent and optional TutorialComponent. Inspect existing [ariff.tres](../../data/npc/presentation/ariff.tres), [researcher.tres](../../data/npc/presentation/researcher.tres) and [RoomQuestManager](../../components/NPCs/enemies/spawner/npc-quest-spawner.gd) configurations.

| Identity | Meaning |
| --- | --- |
| NPCPresentation.npc_id / QuestNPCComponent.npc_id | Stable giver/contact/event identity |
| dialogue_identity | Portrait/timeline presentation selector; can differ from NPC ID |
| QuestData.quest_id | Quest definition identity, never a substitute for giver ID |
| RoomQuestManager.npc_directory key | Spawned NPC identity; configure it consistently with presentation/giver |

## Editor: new quest giver

1. Right-click data/npc/presentation/ → New Resource → NPCPresentation. Set npc_id, display_name, optional portrait, dialogic_character, dialogue_identity, offer_dialogue, accepted, declined and nonnegative intended reoffer_cooldown. Store portraits under assets/ for the conversation restore allowlist. dialogic_character must expose compatible Dialogic portrait data; a generic Resource is not automatically a character.
2. Create an inherited NPC scene. Set its npc_sprite. Keep required unique node names used by npc.gd, including optional component references. Set QuestNPCComponent.npc_id to the same ID, faculty to the authored quest faculty and presentation to your Resource. Configure indicator if desired; leave gameplay behavior in the existing component.
3. Assign a compatible existing Dialogic timeline to DialogicComponent.npc_timeline for nonquest introduction, or use the quest direct-text path through its QUEST_TIMELINE_PATH. The existing quest style reads QuestText/CurrentPortrait. Extend local dialogue assets/portrait branches or assign a suitable project-authored timeline; do not edit addons/Dialogic vendor source for ordinary content.
4. Add the presentation to data/npc/presentation/manifest.gd PRESENTATIONS when it should resolve consistently later from a conversation's npc_id. Direct assignment configures that NPC but is not a general presentation registration step for every UI.
5. Ensure QuestData is in a database loaded by QuestRegistry, with matching faculty and hand_in_npc_id (if set). A quest component has no direct quest_id property; setup requests an eligible quest for its faculty.
6. Configure DetectionComponent.interaction_radius and obstruction_mask (terrain default 16), and WanderComponent.stationary/range/speed. Give NPC body/collision valid ground and an unobstructed player approach. For maintained NPC populations, use RoomQuestManager.npc_directory, safe/access markers and NPCSpawnValidator as below.
7. Enter range, face/focus an accessible NPC, interact, finish introduction, confirm it remains AVAILABLE until the offer's explicit Accept. Test Decline, Escape/dismiss, subsequent reoffer, incomplete dialogue, confirmed hand-in and messaging history/read state. Test two nearby givers so focus/LOS chooses the correct one.

## Safe placement Resource

[NPCSpawnValidator](../../components/NPCs/npc-spawn-validator.gd) is another first-party Resource. Create it through New Resource, assign RoomQuestManager.spawn_validator. Configure allowed_region relative to the spawner, body_size, obstacle_margin, interaction_clearance, minimum_separation, max_attempts, solid_mask, ground_search, max_step and optional fallback feet. The [first actual world-boot fixture](../../tests/npc-world-boot-1.tscn) inherits a production room with an inline NPCSpawnValidator. RoomQuestManager.safe_spawn_markers and access_markers are NodePath arrays; markers represent feet/ground, while placed bodies use their center.

The validator ray-checks support at both feet edges, body clearance, a full-height approach lane and a conservative walking corridor from an access marker. It does not solve jumps/flight/navmesh. A configured fallback still must pass checks. Use [NPC accessibility](../npc-spawn-accessibility.md) and tests/npc-world-boot-1.tscn through -3 plus manual approach review; no “valid looking” random spawn should skip those checks.

## Dialogue, phone and export boundaries

QuestNPCComponent runs narrative then the shared QuestOfferDialog. A single-use decision token validates owner/instance/giver; only explicit Accept calls acceptance. Hand-in uses QuestRewardService, and accepted/declined reactions may use quest overrides before presentation fallbacks. QuestConversationStore records actual decisions/milestones with receipts; the phone renders this store rather than inventing message histories. Reoffer cooldown comes from presentation and is transient; open offer tokens/dialogue windows do not restore from saves.

NPC resources and Dialogic assets must be referenced or included under the exported project/addon import rules. Validate the fresh PCK as well as editor interaction; missing portrait branches can appear as generic fallback rather than a gameplay error. NPC movement/positions are not persistent campaign simulation; world scenes recreate them and reacquire loaded authoritative quest instances.

Common mistakes: mismatched NPC and portrait IDs, missing presentation manifest, faculty with no eligible registered quest, blocked/unreachable spawn, or accepting from a timeline callback. Completion: identity/schema refs correct, accessible body and focus, explicit decision/hand-in behavior, phone history/read state, source/PCK and scene-exit cancellation checked.
