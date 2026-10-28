# Magis Penglipur Lara Developer Handbook

Start with [getting started](getting-started.md), then follow the [three content exercises](authoring/content-authoring-quickstart.md). This handbook describes the local Save V1 implementation, based on `f068151`, using Godot **4.7** (verified installed engine: 4.7.2). Source code and current Resource schemas are the authority; historical reports are evidence of earlier states.

## Create gameplay content

[Authoring index](authoring/README.md) · [Complete property reference](reference/resource-reference.md) · [Registration matrix](reference/content-registration-matrix.md)

| I want to add… | Guide |
| --- | --- |
| A discipline, course or subject | [Fields](authoring/fields.md), [courses and subjects](authoring/courses-and-subjects.md) |
| A spell, mechanic or status | [Spells](authoring/spells.md), [all 15 typed effects](authoring/spell-effects.md), [status effects](authoring/status-effects.md) |
| An enemy or AI behavior | [Enemies](authoring/enemies.md), [AI profiles](authoring/enemy-ai.md), [abilities](authoring/enemy-abilities.md) |
| A three-phase boss | [Bosses](authoring/bosses.md) |
| An item, recipe or drop | [Items and loot](authoring/items-and-loot.md), [crafting](authoring/crafting.md) |
| A quest or character conversation | [Quests](authoring/quests.md), [NPCs and dialogue](authoring/npcs-and-dialogue.md) |
| A room, portal or elevator | [Worlds and scenes](authoring/worlds-and-scenes.md) |
| A tutorial or other presentation data | [Tutorials](authoring/tutorials.md), [additional systems](authoring/additional-systems.md) |

## Understand the implementation

- [System map](architecture/system-overview.md) and [Resource-driven architecture](architecture/data-driven-architecture.md).
- [Resource lifecycle](architecture/resource-lifecycle.md) and [registries/manifests](architecture/registries-and-manifests.md).
- [Combat](architecture/combat-architecture.md), [progression](architecture/progression-architecture.md) and [save/load architecture and content evolution](architecture/save-load-architecture.md).
- [Automatic targeting, Q switching and larger buff icons](auto-targeting-and-buff-hud.md).
- [Snappy casting, E pushback and Spells filters](snappy-combat-and-spell-filters.md), [spell runtime repair and live audit](spell-runtime-repair.md).
- [Save V1 schema and recovery policy](save-system-v1.md), [status HUD](status-effects-hud.md), [accepted-input particles](incantation-input-feedback.md).

## Develop and validate

[Developer workflow](developer-workflow.md) · [Identifiers](reference/identifiers-and-conventions.md) · [Testing](reference/testing-and-validation.md) · [Troubleshooting](reference/troubleshooting.md) · [Checklists](reference/content-checklists.md) · [Maintenance](reference/maintenance-policy.md)

[Documentation audit](documentation-audit.md) records corrected instructions and unmodified code findings. [Handbook validation](reference/handbook-validation.md) distinguishes today's checks from older results.

## Existing detailed references and historical evidence

The historical implementation/migration reports and their logs/screenshots remain intact. Use [the audited document inventory](documentation-audit.md#coverage-and-evidence) to locate every prior page, including Physics/Bakau catalogues, NPC accessibility, spell/enemy/quest internals and boss delivery evidence. Their test counts describe their recorded runs, not a new verification on every documentation edit. Current authoring starts in this handbook.
