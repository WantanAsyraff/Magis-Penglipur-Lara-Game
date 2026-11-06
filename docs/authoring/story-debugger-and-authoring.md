# Story debugger and authoring tools

## Open the tools

Enable **Magis Story Tools** in Project Settings → Plugins. The **Story** bottom panel lists registered arcs, chapters, stages, transitions, an editable authoring graph, and validation findings. Select a Resource to edit its exported fields in the normal Inspector. **Reload & Validate** rereads `res://data/story/definitions/story-database.tres`. The **Actions** toolbar button offers the same commands as right-click menus when right-click input is unavailable.

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

## Authoring stages and transitions

Right-click an empty area of **Story Resources** and choose **New Story...**. Enter a unique lowercase arc ID and display name, plus IDs and names for its first chapter and starting stage. The editor registers all three Resources in one save and opens the new story in the Inspector. Right-click an existing story arc for **Add Chapter...**, or a chapter for **Add Stage...**. Right-click a stage or transition in the tree for editing and the relevant connect or delete actions. These menus work independently of graph dragging. New stories and chapters support editor Undo and Redo.

Open the Story editor panel and select a chapter in the filter. Right-click empty graph space and choose **Add New Stage...**. Choose the chapter and enter a unique, lowercase stable ID. The new `StoryStageData` is registered in the chapter and saved in its owning Resource. Click the stage card to edit its title, objective and other exported fields in the Inspector. Right-click a card for **Set as Chapter Entry**, **Duplicate Stage...**, or **Delete Stage...**. Duplication copies the stage text but starts with no actions or outgoing transitions so it cannot duplicate action receipts or progression IDs. Deleting a stage with incoming or outgoing transitions, or a chapter entry stage, is blocked with a dependency list.

To connect stages by dragging, expand the Story panel, then drag the **green output** port on a source card to the **blue input** port on a destination card. A preview follows the cursor. Releasing over empty space cancels the drag with a status message. The minimap is disabled so it cannot cover a port. Zoom and pan when a destination is outside the visible graph.

To connect without dragging, right-click the source stage and choose **Connect to Stage...**. Search by stage ID, name or chapter, select the destination, and confirm. **Connect From Stage...** chooses a source for the stage you right-clicked. The toolbar **Actions** menu exposes these commands for the selected stage. Both workflows use the same validation, Resource registration, save and undo logic.

New connections create a `StoryTransitionData` in the source stage's `transitions` array, assign a stable ID and target, and open the Resource in the Inspector. **automatic = false** means the graph edge alone will not advance the campaign; configure an explicit trigger, choice, conditions, priority, actions and other fields in the Inspector, then click **Save Transition**. The **Move Source** button changes the owning stage when both stages are saved by the same Resource file. A move between different owning files is rejected to avoid a partial save.

Right-click an existing graph connection to edit, view conditions, copy its ID, or delete it. If multiple authored transitions share one visual edge, choose the exact transition ID first. The transition list below the graph offers the same exact selection. Deletion asks for confirmation. Use the editor's **Undo** and **Redo** commands for stage creation, transition creation/deletion, source moves and chapter entry changes. Right-click empty space for **Arrange Nodes**, **Fit Graph to View**, **Refresh Graph**, and **Validate Story**. The validation list updates after authoring changes; dead ends and unreachable stages remain visible until the narrative author supplies paths.

The current authored prologue has five stages and no production transitions. Do not add canonical progression solely to clear informational findings. Play a stage and inspect the runtime F12 overlay to see live eligibility; that debugger remains read-only.

For input diagnosis, open any Story **Actions** menu and toggle **Interaction diagnostics**. The editor Output panel then reports which Control received a click, nearby port identities, selected stage, and drag start/end events. Turn it off after diagnosis.

### Manual interaction check

In an isolated copy of the database, expand the Story panel at 1280×720 and 1920×1080. At zoom 0.5, 0.75 and 1.0, pan until two stage ports are visible. Press the green output and confirm the preview follows the mouse; release over empty space and check for the cancellation message. Drag again to a blue input, confirm the new transition appears in the Inspector, save it, restart the editor, and verify the edge remains. Right-click empty space, a stage title, stage content, and the edge; check each menu. Use **Connect to Stage...** to create another transition, then delete it and check Undo and Redo. Run **Validate Story** to refresh reachability and dead-end findings. The authoring test fixture under `.godot/` is isolated from production campaign data.

## Troubleshooting

- **Stage never activates:** inspect the outgoing transition on the active stage, its required event and nested condition trace. Check that the target ID is registered.
- **Wrong dialogue:** scan World, select the `StoryDialogueResolver`, inspect variant priorities, condition results and fallback. Quest-owned conversations retain their normal priority.
- **Locked portal:** select the portal under World and inspect its condition trace and destination. This inspection does not start SceneManager.
- **Possible automatic loop:** validation reports an SCC whose internal edges are automatic with no event or choice. Review state-changing termination conditions; cycles are only warnings unless nontermination can be proven.
- **Stale snapshot:** loading or profile changes can temporarily hide live state. The last display is marked STALE and should not be treated as current.

The debugger does not modify Save V1 or store history in campaign saves. Compare story receipts and QuestManager flags before and after inspection when checking read-only behavior; `tests/story-debugger/story-core.tscn` and `story-ui.tscn` perform this check.
