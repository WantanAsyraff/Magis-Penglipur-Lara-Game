# Authored cutscene skipping

[CutsceneSequence](../../data/story/cutscene-sequence.gd) is an explicitly opted-in contract. [CutsceneFlow](../../autoloads/cutscene-flow.gd) coordinates the installed Dialogic APIs and a lower-right hold control. Ordinary Dialogic/NPC/quest-offer callers remain unchanged. Vendor addon source is untouched.

## Author a sequence

1. Create a CutsceneSequence Resource under data/story/. Set a stable sequence_id and a real timeline_path. Defaults are non-skippable; opt in with skippable=true only after reviewing the complete timeline.
2. Choose a unique completion_signal and append the matching Dialogic signal event at the **terminal point** of the timeline. Follow the existing prologue files: the signal argument is story:completed:<sequence ID>. An external end_timeline without this marker is interruption, not completion.
3. Set combat_after and phone_after for the destination gameplay state. Optional grant_spell must reference a canonical registered SpellData. This small contract does not implement arbitrary rewards or invented transitions; a new required effect needs an explicit idempotent completion handler and tests.
4. Optionally author recap text and style_path. The default story-style uses a responsive textbox layout and reserves the lower-right skip gutter at both target resolutions. Ordinary main-style NPC dialogue is unchanged.
5. Export the Resource on the owning scene controller and call CutsceneFlow.play(self, sequence) only after restore has finished. Keep owner alive for the whole sequence. Scene references retain the Resource and timeline in exports; there is no global filename allowlist or folder discovery.
6. Test natural, skipped, interrupted, owner exit, replay/load, input and mandatory-choice cases. Do not attach this to hands-on tutorials or quest decisions merely to obtain a skip button.

## Completion contract

| Outcome | Trigger | Result |
| --- | --- | --- |
| NATURAL | Owned timeline reaches its terminal signal and ends | Restore presentation, apply required context/reward once, persist completion flag |
| SKIPPED | Eligible sequence reaches a 0.8-second intentional hold | Supported Dialogic.end_timeline(true), same required completion effects once |
| INTERRUPTED | Load, owning scene exit, external end or replacement timeline | Cleanup and previous context restoration; no completion flag or award |

The flag story_sequence:<sequence_id> uses existing QuestManager.world_flags and existing autosave. Completed sequences do not replay or re-equip a later player loadout. The owner and exact timeline are tracked, so unrelated timeline signals cannot complete the contract. Inventory is blocked while dialogue owns gameplay. Temporary HUD visibility is restored; school completion enables its normal combat HUD.

The entire sequence is non-skippable if its authored events contain a DialogicChoiceEvent or a DialogicJumpEvent. Branching timeline graphs require separate reviewed contracts. Current awaiting-choice state and QuestOfferDialog also block eligibility. This deliberately conservative rule prevents skipping past a future mandatory decision; split presentation and choice segments into separately reviewed contracts when appropriate. No automatic quest acceptance/rejection is introduced.

## Controls and recap

Hold F1, controller R3 or the visible mouse button for 0.8 seconds. F1 is remappable through Settings and the hint follows the key binding. Ordinary advance, Escape and Back do not skip. Early release or application focus loss cancels progress. A focused skip button also supports controller A; R3 works without requiring pointer focus. The thin progress indicator tracks the hold.

Skipped sequences with authored recap text offer a short-lived optional View recap button. Opening it uses ModalService and closing releases its own pause. Transition and restoration dismiss the view. Recaps are authored content, not runtime-generated summaries and not a persistent journal.

## Integrated callers

| Resource / callers | Completion behavior |
| --- | --- |
| kampung-intro / rumah-yan-entrance | Restore movement and noncombat context; no unrelated Yunira content changed |
| school-entrance / yan-exam-tutorial | Restore movement/combat; grant and equip Kinetic Chill once; practical examination remains playable; no full-curriculum grant |
| after-final-paper / chapter-1 subway | Complete dialogue in place, noncombat, phone hidden; no added transition or reward |
| after-final-paper / FLAC floor-one entrance | Same sequence identity, caller duplicates phone_after=true to preserve its existing context |

Save V1 and Quest V2 versions are unchanged. Old saves have no new sequence flag and can play the introduction once. Existing completion flags persist across fresh-process load. Test with tests/cutscene-skip.tscn, inventory-v2-save and the native preview; [recorded evidence](../reference/inventory-v2-validation.md) distinguishes synthetic controller input from hardware testing.
