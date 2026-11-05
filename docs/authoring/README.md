# Content authoring index

Start with the [three self-contained exercises](content-authoring-quickstart.md). Then choose the actual schema and workflow below. All guides distinguish Resource-only composition from necessary registry/integration or new mechanic code.

| Content family | Canonical guides |
| --- | --- |
| Academic identity/progression | [Fields](fields.md), [courses/subjects](courses-and-subjects.md) |
| Magic and combat payload | [Spells](spells.md), [effects](spell-effects.md), [statuses](status-effects.md) |
| Ordinary enemies | [Definitions/spawning](enemies.md), [utility AI](enemy-ai.md), [abilities](enemy-abilities.md) |
| Boss phases/attacks/arena | [Bosses](bosses.md) |
| Inventory/equipment/drops | [Items and loot](items-and-loot.md), [crafting recipes](crafting.md) |
| Quests/events/rewards | [Quests](quests.md) |
| Givers, presentation and safe spawning | [NPCs/dialogue/NPCSpawnValidator](npcs-and-dialogue.md) |
| World/room/elevator/checkpoint | [Worlds and scenes](worlds-and-scenes.md) |
| Tutorial pages and invocation | [Tutorials](tutorials.md) |
| Legacy spellcaster, lyrics and other scene data | [Additional systems](additional-systems.md) |

Use the [complete property reference](../reference/resource-reference.md) for defaults and Inspector enum/range hints, the [registration matrix](../reference/content-registration-matrix.md) for discovery/export, and [troubleshooting](../reference/troubleshooting.md) for symptoms and fixes. Completion includes actual reachable gameplay, validation, exported references and save compatibility, not just a `.tres` file that can be opened.

Inventory V2: [items and transactions](inventory-and-items.md), [interface and controls](inventory-ui.md), [authored cutscene skipping](cutscene-skipping.md).

## Story progression

- [Architecture](../architecture/story-progression-architecture.md)
- [Arcs and chapters](story-arcs-and-chapters.md)
- [Stages](story-stages.md)
- [Flags](story-flags.md)
- [Conditions](story-conditions.md)
- [Phase 1 validation](../reference/story-phase1-validation.md)

## Story transitions

- [Transition architecture](../architecture/story-transition-architecture.md)
- [Transitions](story-transitions.md)
- [Actions](story-actions.md)
- [Branching](story-branching.md)
- [Phase 2 validation](../reference/story-phase2-validation.md)

## Story saves

- [Save architecture](../architecture/story-save-architecture.md)
- [Persistence authoring](story-persistence.md)
- [Migrations](story-save-migrations.md)
- [Phase 3 validation](../reference/story-phase3-validation.md)

## Story world adapters

- [World integration](story-world-integration.md)
- [Dialogue variants](story-dialogue-variants.md)
- [Conditional events](story-conditional-events.md)
- [Phase 4 validation](../reference/story-phase4-validation.md)

## Story debugging

- [Runtime debugger and editor authoring tools](story-debugger-and-authoring.md)
- [Diagnostic architecture](../architecture/story-debugger-architecture.md)
- [Phase 5 validation](../reference/story-phase5-validation.md)
