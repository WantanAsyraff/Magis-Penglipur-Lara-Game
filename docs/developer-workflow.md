# Developer workflow

## Setup and safe branches

Use Godot 4.7, Python 3 for repository runners, and Git. Check `project.godot`, `git status --short --branch` and your engine version first. Branch from the local state containing the feature you need. For example, after preserving any uncommitted work, `git switch -c content/my-room` creates a content branch from your current checkout. Do not substitute remote main for a newer local feature branch.

Open/import the whole project. Review project.godot after EditorScripts run: addons may rebuild indexes. Do not commit incidental settings, asset reimports, regenerated manifests or scene reformatting unrelated to your change. No justfile exists in this checkout, so there is no `just verify` command here.

## Daily authoring loop

1. Read the schema, its canonical guide and an existing working `.tres`.
2. In FileSystem, right-click the target folder → Create New → Resource, search the exact registered class name, configure it in Inspector and save it. Godot versions may label the menu New Resource; use the Resource creation dialog, not New Script.
3. For nested arrays, increase Array Size, expand an element and choose New <actual class> or drag a saved `.tres` into it. Click its resource to edit the nested Inspector. Use Make Unique before changing a shared definition only for one actor/variant; otherwise every scene referencing it sees the edit.
4. Assign the new Resource to its actual consumer/manifest. Folder placement is not universal registration.
5. Run the smallest relevant test and play the affected scene. Inspect Output for script errors even if Godot's exit code is zero.
6. Check an exported pack; editor-only discovery can hide a missing manifest dependency. Use [testing commands](reference/testing-and-validation.md).
7. Review the diff for IDs, UIDs, all referenced files and unintended shared subresource changes. Update the guide if the authoring interface changed.

## Tools and commands

```bash
flatpak run org.godotengine.Godot --version
flatpak run org.godotengine.Godot --headless --path . --editor --import --quit
flatpak run org.godotengine.Godot --path .
flatpak run org.godotengine.Godot --path . scenes/spell-testing/physics-curriculum-lab.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/spell-regression.tscn -- --quest-test-mode
python3 tools/validate-docs.py
GODOT_COMMAND='flatpak run org.godotengine.Godot' python3 tools/validate-docs.py --check-gdscript
```

The three `.gd` tools in tools/ extend **EditorScript**. Open one in Godot's Script editor and use File → Run (Ctrl+Shift+X). They are not command-line SceneTree scripts for `godot --script`. Spell baking rewrites data/magis/spell-manifest.gd; world baking rewrites autoloads/world-manifest-paths.gd. Review generated changes. There are no item/enemy/quest bake scripts.

Existing Python runners accept `--godot` as one executable path, not a multiword Flatpak command. Use a native executable or a small local executable wrapper containing `exec flatpak run org.godotengine.Godot "$@"`. Do not commit a machine-specific wrapper. For Flatpak, a host /tmp directory may differ from the app's /tmp: use a cache directory under your home for exported packs. See [validation](reference/testing-and-validation.md) for direct commands requiring no wrapper.

## Contributions and maintenance

Commit `.tres`, `.tscn`, new `.gd` and their generated `.uid` files as appropriate. Preserve existing scene/resource UIDs and stable gameplay IDs when moving assets in the Editor. Generated .godot/ and import caches are not source changes. A `.tres` header UID is asset identity; spell/item/quest IDs are save and gameplay identity. Both need deliberate handling.

- [ ] Unique stable IDs; correct class/folder and required fields.
- [ ] References exist and no unintended circular/shared Resource mutation.
- [ ] Correct registry/manifest/scene assignment; generated diffs reviewed.
- [ ] Validator and appropriate suites pass; actual changed content was exercised.
- [ ] Gameplay/visual/manual review performed or explicitly left unverified.
- [ ] Exported resources load; no editor-scan dependency hidden.
- [ ] Save evolution considered; released IDs preserved or migration designed.
- [ ] Canonical handbook/property reference updated in the same change.

Do not write test data to production campaign/legacy saves. Do not push, merge or rewrite unrelated history without authorization. The [maintenance policy](reference/maintenance-policy.md) defines subsystem sources of truth.
