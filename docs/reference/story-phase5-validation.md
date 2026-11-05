# Phase 5 validation

Godot 4.7.2 Flatpak was used on the local checkout. The Story editor plugin loads the registered database and reported five stages and nine findings. The database has no production transition edges: the analyzer reports five dead ends and four structurally unreachable later stages. These are authored-content findings, not debugger runtime failures.

Run focused tests with an isolated `XDG_DATA_HOME` and `--quest-test-mode`:

```bash
flatpak run org.godotengine.Godot --headless --path . tests/story-debugger/story-core.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/story-debugger/story-ui.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --editor --path . --quit -- --story-editor-test
```

The runtime UI was captured at 1280×720 and 1920×1080 in `docs/previews/story-phase5/`. Screenshots show the current authored database. Headless editor automation selected and opened a Resource, refreshed the dock, and removed it on shutdown. Mouse-driven Inspector navigation and editor visual layout were not inspected.

Focused results on this checkout: story core 21/21, runtime UI 10/10, story foundation 24/24, transitions 20/20, save 20/20, world integration 28/28, and quest pipeline 172/172. Quest persistence writer and reader passed 4/4 and 7/7. The full Save V1 reader passed 20/20, but its writer failed one existing particle-pool assertion twice (59/60). The cutscene skip suite reached 29/29 and prologue inventory integration reached 28/28 but both processes ended with code 134 after the assertion marker; investigate the shutdown separately before treating either as a clean process pass. The environment prologue suite passed 8/8. The editor loaded five stages and nine findings and removed the dock on shutdown without script errors.

Generated isolated graph timings: 10 stages/17 edges: 246 µs; 100/197: 4,456 µs; 500/997: 88,748 µs. These are single local runs and do not establish a frame-time guarantee. Static analysis is launched on demand.

The handbook validator currently stops on an unrelated uncommitted destruction Resource without a guide (`AreaExplosionBehavior`); Phase 5 links were added, but the whole documentation validator does not pass on this worktree.

The Web PCK exported and its story core fixture passed 18/18 from a fresh engine process. A full Web release export could not start because this Flatpak profile has no 4.7.2 Web debug/release export templates. Running the PCK with the editor executable reported `OS.has_feature("debug") == true`, so that run is **not** proof that the F12 overlay is absent in an actual release executable. The runtime code gates creation and activation on that feature, but release behavior remains unverified.

StoryDebugService keeps history in memory only. It cannot reconstruct the outcome of a historical cutscene from a completion flag alone: a completed flag proves natural or successful skipped completion, while an interrupted cutscene remains incomplete. The actual in-session outcome is recorded only when CutsceneFlow emits it during that debug session.
