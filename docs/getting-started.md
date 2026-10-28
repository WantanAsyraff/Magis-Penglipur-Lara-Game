# Getting started

This is a Godot 4.7 GL Compatibility project. Open the repository's `project.godot`, not an individual scene in an empty project. Use 4.7-compatible Godot; the local verification installation is `flatpak run org.godotengine.Godot` reporting 4.7.2. Do not change config/features to accommodate an older executable.

1. Obtain the authorized repository/local branch. The latest handbook base is the local `feature/combat-feedback-status-hud-save-v1`, not necessarily remote main. Inspect `git status` before changing branches.
2. Open Godot's Project Manager, Import, select project.godot, then Edit. Wait for filesystem import and script-class registration. Keep addons enabled as authored; Dialogic and SceneManager are dependencies, not optional files to delete after an error.
3. Confirm the FileSystem shows data/, components/, scenes/, autoloads/ and tools/. A class missing from New Resource usually indicates a parse/import failure; inspect Output first.
4. F6 runs the current scene, F5 runs the configured main menu. New Game selects a campaign profile; ordinary Save/Load is available only for supported single-player campaign scenes.
5. For experimentation run the Physics or Enemy lab directly with `--quest-test-mode` as described in [testing](reference/testing-and-validation.md). Labs supply temporary loadouts and are not campaign save destinations. Never test against production save slots.
6. Before creating content, read the [registration matrix](reference/content-registration-matrix.md). Most failures involve an unreferenced Resource, an incorrect ID, or content unavailable in an exported pack.
7. Follow the [quickstart](authoring/content-authoring-quickstart.md); it identifies the small registry edits needed and which core controllers should remain untouched.

Existing placeholder art, warning diagnostics, unsupported replication and transient save boundaries are documented, not promises of release readiness. Tests do not establish visual balance or a complete narrative playthrough.
