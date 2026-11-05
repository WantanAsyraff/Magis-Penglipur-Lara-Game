# Story debugger and authoring tools

## Open the tools

Enable **Magis Story Tools** in Project Settings → Plugins. The **Story** bottom panel lists registered arcs, chapters, stages, transitions, a read-only graph, and validation findings. Select a Resource and press **Open Resource** to edit its exported fields in the normal Inspector. **Reload & Validate** rereads `res://data/story/definitions/story-database.tres`.

In a debug game build, press **F12** for the runtime overlay. F12 is unavailable in release builds. The overlay does not pause gameplay or start a conversation. It will not open during a cutscene or modal interaction. Use **Close F12** to return to play. Opening, refreshing, and closing do not save or advance progression.

## Read the runtime tabs

- **Overview** shows the active arc, chapter, stage, objective and outgoing transition status.
- **Graph** pans and zooms over authored stages; search or filter by chapter, select a stage for transition details, and use **Focus active**.
- **State** shows registered flag values, explicit/default distinction, choices, and transition, action, and dialogue receipts.
- **World** scans the current scene on demand for story-aware components. Selecting a row shows dialogue variants, presence and device conditions, portal gates, or cutscene eligibility. Removed targets show as unavailable.
- **What-if** lists supported conditions on the active stage. Select one, enter a JSON value such as `true`, `80`, or `"prologue.leave_house"`, and press **Preview condition**. Results are labelled SIMULATED and never written to live state. Quest, cutscene, inventory and other live-only conditions remain UNKNOWN.
- **Events** shows only events observed in this diagnostic session. Save receipts are separate and appear under State.
- **Validation** shows structural authoring findings. An INFO dead end can be intentional; an ERROR missing target needs correction.

Select a graph stage to see each outgoing transition and nested condition trace. `PASS` and `FAIL` are evaluated facts; `UNKNOWN` means unavailable or unsupported; `ERROR` means invalid authoring; `SKIPPED` indicates a short-circuited child. `WAITING_FOR_EVENT` means a current-stage event is still required. The debugger never publishes that event.

## Authoring walkthrough: inspect the existing prologue

Open the Story editor panel and select `prologue.wake_up` under the registered prologue chapter. Its objective and stage ID appear in the Resource Inspector. Run **Reload & Validate**. The current authored database has five prologue stages and no active production transitions; the graph therefore reports disconnected later stages and dead-end informational findings. This is expected until production transitions are authored and does not mean the debugger should advance the story.

To inspect a new transition, create a `StoryTransitionData` Resource in the stage's `transitions` array, give it a stable `transition_id` and a registered `target_stage_id`, configure its existing `conditions` and event/choice fields, then reload the panel. The graph draws the new edge and validation checks the target. Play the stage and select its graph card to see live eligibility. Do not edit canonical prologue progression simply to clear findings.

## Troubleshooting

- **Stage never activates:** inspect the outgoing transition on the active stage, its required event and nested condition trace. Check that the target ID is registered.
- **Wrong dialogue:** scan World, select the `StoryDialogueResolver`, inspect variant priorities, condition results and fallback. Quest-owned conversations retain their normal priority.
- **Locked portal:** select the portal under World and inspect its condition trace and destination. This inspection does not start SceneManager.
- **Possible automatic loop:** validation reports an SCC whose internal edges are automatic with no event or choice. Review state-changing termination conditions; cycles are only warnings unless nontermination can be proven.
- **Stale snapshot:** loading or profile changes can temporarily hide live state. The last display is marked STALE and should not be treated as current.

The debugger does not modify Save V1 or store history in campaign saves. Compare story receipts and QuestManager flags before and after inspection when checking read-only behavior; `tests/story-debugger/story-core.tscn` and `story-ui.tscn` perform this check.
