# Documentation audit

This audit uses the local `feature/combat-feedback-status-hud-save-v1` state at `f068151`, not remote main. Work proceeds on `docs/complete-developer-handbook`. The initial working tree was clean. Applicable local instructions are `/home/wantansirap/AGENTS.md`; no repository-specific AGENTS.md exists. Gameplay scripts, Resources, manifests, IDs, UIDs and save schemas are outside this documentation change.

## Findings and resolution

| Previous issue | Source evidence | Resolution |
| --- | --- | --- |
| Root README says technical docs are coming soon | Existing docs and SaveManager already exist | Replace placeholder with handbook/quickstart links |
| 797-line technical overview describes earlier quest/enemy flow and missing Save | `autoloads/save-manager.gd`, `components/quests/quest-registry.gd` | Replace stale overview with current architecture map and canonical links |
| Spell authoring says Godot 4.6 and default confirmation | `project.godot` features 4.7; `Player.incantation_strategy` is CHAINED | Canonical spell guide uses 4.7 and documents all strategies |
| Enemy guide calls O a confirmation control and states guardian stats different from current file | Player resolver; `definitions/training-guardian.tres` uses default stats subresource values | Redirect to current enemy guide; tell authors to inspect actual definition/defaults |
| Physics coverage labels confirmation as current implementation | `components/spells/incantation-resolver.gd`, Player | Correct current guidance; preserve old verification dates/results |
| Assistant document's early sections describe panels/predictions removed by its later minimalist update | `scenes/ui/spell-combat-ui/incantation-assistant.gd` | Mark as historical design/delivery record; current status block points to actual compact row |
| Spell architecture says complete academic saves are future work | `components/save/game-save-schema.gd` captures academic state | Update current limit paragraph and link Save V1 |
| Quest pipeline/save/conversation text claims only partial saves, repair-on-load/coalesced legacy persistence | `QuestManager.apply_staged`, `schedule_save`, `SaveManager._restore` | Explain embedded Quest V2 bundle, explicit import, milestone autosaves and controlled outbox recovery |
| WorldManifest warning refers to an underscore-named bake script that does not exist | Actual tool is `tools/bake-world-manifest.gd` | Document exact hyphenated tool; record code-message defect without modifying it |
| Assuming folder discovery applies to every Resource | Spell library editor scan; manual enemy/item/presentation manifests; hardcoded quest database list | Add explicit registration matrix and export lifecycle |
| P described as clearing and cancelling casts | project.godot binds P to clear_incantation; cancel_casting events are empty; Player methods are separate | Correct current control guidance and document Settings binding |
| No complete property inventory or dormant-field distinction | Every first-party Resource schema and runtime consumer audit | Generate schema-checked reference; document dormant fields explicitly |
| Crafting could be mistaken for hardcoded recipes or a RecipeData class | ItemData ingredient/qty fields; CraftingRoom.available_recipes | Document actual Resource-based ItemData recipes and missing equipment/shop semantics |
| Academic “classes” could imply a character-class Resource | Player identity strings only; no character-class Resource schema | Distinguish subjects, identity labels and GDScript class_name |
| Additional typed placement Resource absent from requested list | `components/NPCs/npc-spawn-validator.gd` extends Resource | Include NPCSpawnValidator, ElevatorFloor and legacy NPCSpellcasterData |
| Historical 4.6 commands/counts look like current setup instructions | Earlier implementation/migration reports | Add historical notices; retain original evidence and link current workflow |

No broken Markdown destination links were found in the initial 33-page audit. Bare code paths and claims still required source reconciliation; a valid hyperlink does not establish a correct instruction.

## Implementation defects / boundaries found, not changed

- SpellData retains unused resonance/archetype restrictions, tether tuning, `status_effects`, misfire and proc metadata; new values do not create handlers.
- Ability `weight` chooses the highest-weight usable ability; ordinary enemy utility AI is not random weighted selection. Boss attack weights are random within the eligible pool.
- Quest `auto_accept_next` remains serialized but chains require explicit acceptance. Branch storage is not a branching dialogue editor.
- Boss phases/attacks have no standalone `validate()` method. Test thresholds/order, finite nonnegative values and telegraph geometry manually and through the boss suite.
- Item type/value/sellability do not establish a shop or slot-restriction/stat system. Equipment currently swaps items in Inventory_Manager; pickup effects are not a complete explicit-use consumable framework.
- SaveManager supports campaign roots with the exact ZoneRoot script, not arbitrary subclasses; new courses need a `GameSaveSchema.COURSES` entry. Ordinary data authoring sometimes needs a registry reference edit, not a gameplay-controller rewrite.
- NPCSpawnValidator is a conservative grounded walking/approach check, not a navigation or jump planner. Training Guardian defaults must be read from the current Resource, not historical prose.
- SceneData.default_spawn_marker is consumed by elevator selection; ZoneRoot's ordinary fallback searches PlayerSpawn. Portal overrides should be explicit.
- Crafting directly commits an inventory plan; it does not trigger pickup-based health/mana/XP/spell effects. A crafting room is not itself a supported campaign save destination.
- The listed low-grade mana-vile recipe has no ingredient references; the current inventory plan therefore allows an input-free output when capacity permits. Medium/high-grade recipes have explicit inputs. No balance change is made.
- CraftingUI directly assigns the validated inventory plan without a separate server-authority gate in its craft callback; it must not be exposed as an authorized multiplayer crafting service without extending that boundary. No gameplay fix is made here.
- No generic character-class, RecipeData, persistent timed-effect or multiplayer campaign-save system exists.

## Coverage and evidence

The per-file disposition below covers every Markdown file present at task start. New canonical pages live under architecture/, authoring/ and reference/. Specialized Save V1, status HUD and accepted-input pages remain authoritative implementation details. Historical test counts and captured evidence are not today's test results. Current documentation checks are recorded in [validation](reference/handbook-validation.md).

| Existing document | Disposition |
| --- | --- |
| [README.md](README.md) | Replaced by canonical handbook navigation |
| [bakau-integration-tests.md](bakau-integration-tests.md) | Historical notice; original measurements retained |
| [bakau-quest-catalogue.md](bakau-quest-catalogue.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [boss-prototype.md](boss-prototype.md) | Historical notice; original measurements retained |
| [combat-save-v1-verification.md](combat-save-v1-verification.md) | Historical notice; original measurements retained |
| [enemy-ai-profiles.md](enemy-ai-profiles.md) | Replaced by canonical handbook navigation |
| [enemy-authoring-guide.md](enemy-authoring-guide.md) | Replaced by canonical handbook navigation |
| [enemy-magis-integration.md](enemy-magis-integration.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [enemy-migration-report.md](enemy-migration-report.md) | Historical notice; original measurements retained |
| [enemy-pipeline-v2.md](enemy-pipeline-v2.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [incantation-chain-assistant.md](incantation-chain-assistant.md) | Historical notice; original measurements retained |
| [incantation-input-feedback.md](incantation-input-feedback.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [magis-pipeline.md](magis-pipeline.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [monster-drop-catalogue.md](monster-drop-catalogue.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [npc-spawn-accessibility.md](npc-spawn-accessibility.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [physics-curriculum.md](physics-curriculum.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [physics-implementation-coverage.md](physics-implementation-coverage.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [physics-spell-catalogue.md](physics-spell-catalogue.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [physics-spell-interactions.md](physics-spell-interactions.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [quest-authoring-guide.md](quest-authoring-guide.md) | Replaced by canonical handbook navigation |
| [quest-conversation-model.md](quest-conversation-model.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [quest-dialogue-ui.md](quest-dialogue-ui.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [quest-event-integration.md](quest-event-integration.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [quest-migration-report.md](quest-migration-report.md) | Historical notice; original measurements retained |
| [quest-pipeline-v2.md](quest-pipeline-v2.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [quest-save-format.md](quest-save-format.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [save-system-v1.md](save-system-v1.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [spell-architecture-v2.md](spell-architecture-v2.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [spell-authoring-guide.md](spell-authoring-guide.md) | Replaced by canonical handbook navigation |
| [spell-migration-guide.md](spell-migration-guide.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [spell-pipeline-v2-report.md](spell-pipeline-v2-report.md) | Historical notice; original measurements retained |
| [status-effects-hud.md](status-effects-hud.md) | Reviewed; current guidance reconciled or linked to canonical handbook |
| [technical-overview.md](technical-overview.md) | Replaced by canonical handbook navigation |
