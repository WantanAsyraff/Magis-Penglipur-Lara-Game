# Story dialogue skip integration

Verified on 2026-10-31 (Asia/Kuching), Godot 4.7.2.

The active environmental-interactions checkout still launched its prologue timelines directly and had no CutsceneFlow autoload or skip input action. The authored skip implementation is now connected here, including its completion markers, Resources, responsive story layout and four actual scene controllers. No branch merge, vendor changes, ordinary NPC edits or user scene/theme edits were needed.

## Use

During eligible story dialogue, the lower-right button reads **F1 / R3 · Hold to skip**. Hold the mouse button, F1 or controller R3 for 0.8 seconds. Releasing early cancels. Settings includes the remappable skip action. Explicit Escape/B cancellation bindings also allow the optional recap to release modal ownership correctly.

Kampung, school entrance and after-final-paper are eligible. After-final-paper has two callers: subway and FLAC entrance; their original phone/combat context is preserved. School grants/equips only Kinetic Chill once and leaves practical examination gameplay intact. Natural and deliberate skipped completion share persistent story flags; interrupted/loading/owner-exit dialogue never grants completion. Completed sequences do not replay or overwrite later equipment.

Ordinary NPC conversations, quest decisions, choices and branching/jump timelines do not automatically become skippable. New content must opt into a tested CutsceneSequence completion contract; see [authoring guide](authoring/cutscene-skipping.md).

## Implementation and checks

The integration adds autoloads/cutscene-flow.gd, components/story/story-dialogue-layout.*, data/story/ Resources and dialogue/styles/story-style.tres. It updates only the four relevant story controllers and adds terminal signals to their three authored timelines. The skip controller also handles players/cameras that spawn after dialogue starts, keeping gameplay HUDs hidden until the story resolves. project.godot registers CutsceneFlow, cutscene_skip and explicit UI cancel bindings; Settings exposes the key binding.

The existing user edits in the inventory theme, project settings and three world/testing scenes remain preserved. No push or merge was performed.

Commands (isolated test mode):

```bash
flatpak run org.godotengine.Godot --headless --path . tests/cutscene-skip.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --path . tests/prologue-inventory-integration.tscn -- --quest-test-mode --capture-prologue --720
flatpak run org.godotengine.Godot --path . tests/prologue-inventory-integration.tscn -- --quest-test-mode --capture-prologue
flatpak run org.godotengine.Godot --headless --path . tests/environment-prologue.tscn -- --quest-test-mode
```

The skip suite completes 29 checks with zero assertion failures. The native integration loads all four production scenes, verifies visible onscreen buttons and hidden gameplay HUDs, holds physical F1 and checks scene/movement/combat/phone/reward state. It completes 34 checks including six screenshot captures per resolution. Fresh-process Save V1 writer/reader checks also complete 8/0 and 10/0, retaining skipped story flags and profile isolation. The environmental prologue suite completes 8 checks with zero failures, including preserved walkable routes and no unapproved spell grants during restore.

The installed engine still aborts at process shutdown after dialogue, a condition previously reproduced on unchanged main. Assertion completion is therefore reported separately from clean process exit; no clean-exit PASS is claimed for dialogue suites. Existing UID/world-ID and engine texture/resource shutdown diagnostics remain. Physical controller hardware is not connected; synthetic controller action/cancel coverage is included.

## Actual screenshots

| Story | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Kampung | [Skip visible](previews/story-skip/1280x720/skip-rumah-yan-entrance.png) | [Skip visible](previews/story-skip/1920x1080/skip-rumah-yan-entrance.png) |
| School | [Skip visible](previews/story-skip/1280x720/skip-yan-exam-tutorial.png) | [Skip visible](previews/story-skip/1920x1080/skip-yan-exam-tutorial.png) |
| Subway | [Skip visible](previews/story-skip/1280x720/skip-subway-scene.png) | [Skip visible](previews/story-skip/1920x1080/skip-subway-scene.png) |
| FLAC | [Skip visible](previews/story-skip/1280x720/skip-FLAC-F1-entrance.png) | [Skip visible](previews/story-skip/1920x1080/skip-FLAC-F1-entrance.png) |
