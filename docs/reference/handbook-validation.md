# Handbook validation and changed files

Verified on 2026-10-28 (Asia/Kuching), using installed Godot **4.7.2.stable.flathub.ed1daf0bf** against the local Save V1 base `f068151`. The task branch is `docs/complete-developer-handbook`. No gameplay scripts, Resources, manifests, identifiers, UIDs, scenes, tests, project settings or save schemas changed. The only non-documentation source addition is the dependency-free Python documentation helper.

## Checks executed for this documentation task

| Check | Actual result |
| --- | --- |
| Local Markdown links/anchors and concrete res:// paths | Final count recorded below; zero errors |
| Source Resource-to-guide inventory | 42 first-party Resource classes covered |
| Generated property reference drift | 409 exported properties, no drift |
| Godot Resource introspection | 42 classes / 409 actual exported properties, zero failures |
| Native `.tres` examples | 2 examples loaded; SpellData composition also passes SpellValidator |
| Executable GDScript examples | 2 compiled in normal project/autoload context, zero failures; example functions were not called |
| Negative checker cases | Missing local link, stale generated reference and invalid executable script each rejected with exit 1 as intended |
| Editor import | Exit 0; no script/parse/missing-resource errors |
| Source spell/enemy/quest/boss regression | 71 / 138 / 172 / 70 checks, zero failures; each process exit 0 (451 assertions total) |
| Fresh Web-preset PCK export | Exit 0; local validation artifact outside repository |
| Packed spell regression | 71 checks, zero failures, process exit 0 |
| Historical preservation | Nine historical bodies retained verbatim; assistant report retained except relabelling its API signature as nonexecutable text |
| Gameplay diff against f068151 | Empty for autoloads/, components/, data/, scenes/, tests/ and project.godot |
| Whitespace | git diff --check passed |

Raw [check logs](../verification/handbook/) are committed with ANSI/trailing whitespace normalized. These are today's checks; prior reports keep their original run counts and engine versions. The checker scans first-party GDScript Resource declarations, not vendor documentation or every possible natural-language claim. Registration/semantics were reviewed against actual source consumers in addition to these mechanical checks.

Final documentation scan: **DOCS: 70 Markdown files, 1069 local link/path checks, 42 Resource classes, 409 exported properties**.

## Reproduce

```bash
python3 tools/validate-docs.py
GODOT_COMMAND='flatpak run org.godotengine.Godot' python3 tools/validate-docs.py --check-gdscript --check-resources
flatpak run org.godotengine.Godot --headless --path . --editor --import --quit
flatpak run org.godotengine.Godot --headless --path . tests/spell-regression.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/enemy-pipeline.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/quest-pipeline.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/boss-prototype.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . --export-pack Web /home/wantansirap/.cache/mpl-handbook-validation/handbook.pck
flatpak run org.godotengine.Godot --headless --main-pack /home/wantansirap/.cache/mpl-handbook-validation/handbook.pck tests/spell-regression.tscn -- --quest-test-mode
git diff --check f068151
```

The temporary examples/runner scenes live in .godot/ only during checks and are removed afterward. No experimental gameplay content was added. Save-accessing regression tests used --quest-test-mode and their existing isolated fixture filenames. There is no justfile; no `just verify` run is claimed.

## Limits and source findings

- No manual full playthrough of the hypothetical quickstart exercises was performed. Their schemas, composed native examples, named APIs/paths, registration steps and execution consumers were checked; UI ergonomics, tuning and new-content balance still need actual author review.
- This task reran four source suites and one packed suite, not every historical suite. It did not repeat the Save V1 writer/reader campaign durability suite because persistence code/schema are unchanged. Older save durability reports remain linked as historical evidence.
- Vendor Dialogic schemas are integrated through local components, not exhaustively redocumented. Built-in Godot Resource types are dependencies rather than additional project-specific schemas. All **42 discovered first-party Resource classes** have a guide and property reference.
- Generic character-class/RecipeData systems, gear-stat recomputation, automatic arbitrary-status mechanics, general navmesh/squad/flight AI, boss reward/campaign wiring and complete multiplayer replication remain unsupported or require explicit code extensions. Crafting lacks a separate authority gate around its direct UI plan commit; this is documented, not fixed. New course save allowlists and new quest database paths require explicit code reference edits.
- Existing asset UID fallback, uppercase scene-ID, camera/layout and 25-resource/ObjectDB shutdown diagnostics remain. They were reported separately from runtime errors; clean/warning-free shutdown is not claimed. Browser/WebAssembly execution, power-loss durability and balance are not established by PCK resource loading.
- See [the audit](../documentation-audit.md) for all corrected contradictions and untouched code/content findings. Future schema/registration/API changes must update the handbook under [the maintenance policy](maintenance-policy.md).

## Changed files

New and updated Markdown lists below are generated from the actual branch diff against f068151. Tooling is tools/validate-docs.py; evidence is under docs/verification/handbook/. No runtime file is included.

### New documentation (36)

- [docs/architecture/combat-architecture.md](../architecture/combat-architecture.md)
- [docs/architecture/data-driven-architecture.md](../architecture/data-driven-architecture.md)
- [docs/architecture/progression-architecture.md](../architecture/progression-architecture.md)
- [docs/architecture/registries-and-manifests.md](../architecture/registries-and-manifests.md)
- [docs/architecture/resource-lifecycle.md](../architecture/resource-lifecycle.md)
- [docs/architecture/save-load-architecture.md](../architecture/save-load-architecture.md)
- [docs/architecture/system-overview.md](../architecture/system-overview.md)
- [docs/authoring/README.md](../authoring/README.md)
- [docs/authoring/additional-systems.md](../authoring/additional-systems.md)
- [docs/authoring/bosses.md](../authoring/bosses.md)
- [docs/authoring/content-authoring-quickstart.md](../authoring/content-authoring-quickstart.md)
- [docs/authoring/courses-and-subjects.md](../authoring/courses-and-subjects.md)
- [docs/authoring/crafting.md](../authoring/crafting.md)
- [docs/authoring/enemies.md](../authoring/enemies.md)
- [docs/authoring/enemy-abilities.md](../authoring/enemy-abilities.md)
- [docs/authoring/enemy-ai.md](../authoring/enemy-ai.md)
- [docs/authoring/fields.md](../authoring/fields.md)
- [docs/authoring/items-and-loot.md](../authoring/items-and-loot.md)
- [docs/authoring/npcs-and-dialogue.md](../authoring/npcs-and-dialogue.md)
- [docs/authoring/quests.md](../authoring/quests.md)
- [docs/authoring/spell-effects.md](../authoring/spell-effects.md)
- [docs/authoring/spells.md](../authoring/spells.md)
- [docs/authoring/status-effects.md](../authoring/status-effects.md)
- [docs/authoring/tutorials.md](../authoring/tutorials.md)
- [docs/authoring/worlds-and-scenes.md](../authoring/worlds-and-scenes.md)
- [docs/developer-workflow.md](../developer-workflow.md)
- [docs/documentation-audit.md](../documentation-audit.md)
- [docs/getting-started.md](../getting-started.md)
- [docs/reference/content-checklists.md](content-checklists.md)
- [docs/reference/content-registration-matrix.md](content-registration-matrix.md)
- [docs/reference/handbook-validation.md](handbook-validation.md)
- [docs/reference/identifiers-and-conventions.md](identifiers-and-conventions.md)
- [docs/reference/maintenance-policy.md](maintenance-policy.md)
- [docs/reference/resource-reference.md](resource-reference.md)
- [docs/reference/testing-and-validation.md](testing-and-validation.md)
- [docs/reference/troubleshooting.md](troubleshooting.md)

### Updated documentation (34)

- [README.md](../../README.md)
- [docs/README.md](../README.md)
- [docs/bakau-integration-tests.md](../bakau-integration-tests.md)
- [docs/bakau-quest-catalogue.md](../bakau-quest-catalogue.md)
- [docs/boss-prototype.md](../boss-prototype.md)
- [docs/combat-save-v1-verification.md](../combat-save-v1-verification.md)
- [docs/enemy-ai-profiles.md](../enemy-ai-profiles.md)
- [docs/enemy-authoring-guide.md](../enemy-authoring-guide.md)
- [docs/enemy-magis-integration.md](../enemy-magis-integration.md)
- [docs/enemy-migration-report.md](../enemy-migration-report.md)
- [docs/enemy-pipeline-v2.md](../enemy-pipeline-v2.md)
- [docs/incantation-chain-assistant.md](../incantation-chain-assistant.md)
- [docs/incantation-input-feedback.md](../incantation-input-feedback.md)
- [docs/magis-pipeline.md](../magis-pipeline.md)
- [docs/monster-drop-catalogue.md](../monster-drop-catalogue.md)
- [docs/npc-spawn-accessibility.md](../npc-spawn-accessibility.md)
- [docs/physics-curriculum.md](../physics-curriculum.md)
- [docs/physics-implementation-coverage.md](../physics-implementation-coverage.md)
- [docs/physics-spell-catalogue.md](../physics-spell-catalogue.md)
- [docs/physics-spell-interactions.md](../physics-spell-interactions.md)
- [docs/quest-authoring-guide.md](../quest-authoring-guide.md)
- [docs/quest-conversation-model.md](../quest-conversation-model.md)
- [docs/quest-dialogue-ui.md](../quest-dialogue-ui.md)
- [docs/quest-event-integration.md](../quest-event-integration.md)
- [docs/quest-migration-report.md](../quest-migration-report.md)
- [docs/quest-pipeline-v2.md](../quest-pipeline-v2.md)
- [docs/quest-save-format.md](../quest-save-format.md)
- [docs/save-system-v1.md](../save-system-v1.md)
- [docs/spell-architecture-v2.md](../spell-architecture-v2.md)
- [docs/spell-authoring-guide.md](../spell-authoring-guide.md)
- [docs/spell-migration-guide.md](../spell-migration-guide.md)
- [docs/spell-pipeline-v2-report.md](../spell-pipeline-v2-report.md)
- [docs/status-effects-hud.md](../status-effects-hud.md)
- [docs/technical-overview.md](../technical-overview.md)
