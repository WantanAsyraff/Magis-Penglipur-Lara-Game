# Quest Pipeline V2

Quest definitions live in `data/quests/`; runtime state lives in `QuestInstance`. Four original FLAC definitions and ten Bakau definitions load through `QuestRegistry`. Existing faculty numbers 0–5, objective numbers 0–3, resource UIDs, quest/objective IDs and FLAC rewards retain their meanings. Technology & Science is faculty 6.

## Flow and ownership

```
Enemy / Inventory / Magis / NPC / World
    → GameplayEvent → QuestManager.publish
    → QuestObjectiveEvaluator → QuestInstance
    → QuestRewardService → QuestSaveService
    → quest signals → journal / NPC / goals
```

Events carry a receipt, type, owner, actor, target, source, quantity, tags and metadata. Routing is authoritative and receipts are deduplicated by owner. Every eligible instance for that owner receives the event, so one kill can advance several accepted quests. Enemy IDs match exactly; tags must be explicitly configured. Combat never embeds quest IDs.

`AVAILABLE → ACTIVE → COMPLETE → HANDED_OFF` separates readiness from rewarded completion. Only ACTIVE accepts new required progress; optional progress can continue while COMPLETE. Held inventory changes can return COMPLETE to ACTIVE. Cancellation and configured active expiration preserve history. NPC departure expires unaccepted offers but preserves ACTIVE/COMPLETE instances and their hand-in association. A respawned NPC uses its stable ID to recover the instance.

Definitions specify prerequisites, faculty/region/pool, objective dependencies/groups, collection policy, reward resources, hand-in NPC, repeatability and next quest. The manager validates acceptance and hand-in. The native API is for trusted gameplay code; it is not an exposed client command protocol.

## Evaluation

Each objective has its own progress key, capped at the requirement. Mixed collection uses one objective with several target IDs; distinct requirements use separate objectives. Optional objectives and optional groups do not block readiness. ALL groups require every mandatory member; ANY groups require their configured minimum. Ordered objectives snapshot eligibility before processing an event, preventing a single event from cascading through successive steps.

Collection policies are cumulative after acceptance (default for all Bakau quests), currently held, or delivery. Held/delivery reconcile inventory on acceptance, changes, load and claim. Delivery allocates items once across required objectives and removes them in the reward transaction; an ANY group consumes its completed selected routes. Missing/overlapping delivery requirements leave a recoverable pending claim. Author unambiguous delivery alternatives: the allocator prefers narrower target sets and does not solve arbitrary overlapping set-allocation problems.

## Rewards and chains

The reward service is the sole XP/currency/item/spell/flag reward path. It validates owner, state, hand-in target, objectives, claim ledger and inventory capacity. It plans delivery plus rewards, then stages inventory, progression, completed IDs, claim marker and event outbox in a single snapshot. Failed persistence rolls everything back; full inventory leaves the quest ready with a visible explanation. Signals and reward acquisition events follow durable success. Repeated callbacks or load cannot repeat a claim. Nonrepeatable quests also guard against a second instance of the same quest.

Reward item quantities are fixed and bundles are rejected by registry validation. Loot probabilities do not randomize quest rewards. `next_quest_id` offers a real next instance after hand-in; `auto_accept_next` optionally accepts it. Restore resumes an interrupted post-claim chain if no next instance exists. `selected_branch` is persisted extension state; no branching-choice UI is supplied.

## Presentation and integration

`QuestNPCComponent` uses declared resource dialogue with existing NPC fallback strings. Closing an offer/ready Dialogic sequence does not accept/claim. `QuestBoard` is a reusable Area2D with NPC identity, region and database exports, acceptance, claim, tracking and optional researcher dialogue. It pauses gameplay while browsing. The Bakau field lab configures it with the Bakau database. The regular phone journal displays all registered quests and their independent progress; it cannot accept quests away from a giver. Layout uses scrolling containers and wrapping labels.

Tracked goals update only the quest-owned goal lines, retaining nonquest lines. The journal preserves all active quests regardless of tracking selection. Pause-menu Save now invokes the supported quest/inventory snapshot service.

## Export and limits

Databases and explicit item/enemy manifests retain dependencies in exported packs; runtime does not scan resource folders. Registry loading is deferred through runtime resource paths to avoid GDScript cyclic compilation through spell scenes and autoload hooks. Add quests to databases and new enemy definitions to the enemy manifest. New drops on existing registered EnemyData load through loot references without a script change; standalone items use the item manifest.

Authority gates, player attribution and owner isolation are implemented. Remote player inventory/reward storage, party sharing, RPC validation and synchronization are not implemented. The supported save is one active local owner. No position, scene, health, enemy population, transient world object, equipment-stat recomputation or full campaign restore is claimed. World flags are retained, but world scenes must apply them themselves. Event/acquisition receipt histories currently grow; production compaction needs an explicit retention policy. Timers are opt-in wall-clock expiry, not fresh-specimen simulation.

See [authoring](quest-authoring-guide.md), [events](quest-event-integration.md), [save format](quest-save-format.md), [test evidence](bakau-integration-tests.md), [migration](quest-migration-report.md) and the two catalogues.
