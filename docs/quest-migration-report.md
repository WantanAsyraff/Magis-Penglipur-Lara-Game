# Quest Pipeline V2 migration report

## Initial audit

Base: `2cb873c`, `refactor/enemy-pipeline-v2`; working branch: `refactor/quest-pipeline-v2`. Magis and Enemy V2 are implemented and tested. Existing local player, loot, Physics resource, vendor, project and world-scene changes are preserved and excluded from quest commits. Ancestor AGENTS.md requires scoped changes and verification; no justfile exists.

| Area | Actual baseline |
| --- | --- |
| Registry | Four FLAC quests only; no Bakau IDs |
| Runtime | Basic mutable instance progress; no dependency/optional rules, owner partition, reward ledger or restore |
| Events | Enemy observer scans quests directly (exact IDs already fixed); notify_item_collected is absent |
| Rewards | NPC callbacks award XP/currency outside manager; repeated callback path can duplicate rewards; item rewards unused |
| Inventory | Silent stack truncation, no acquired quantity result, missing notification method, duplicate pickup-side objective hook |
| Drops | V2 once-only guards and bundled extra_drops already work; independent per-item Bakau tables missing |
| NPC | ACTIVE instances may survive one release path but lose mapping; alternate despawn path deletes them |
| UI | Only ACTIVE quests; goals replace other quests; COMPLETE/locked/selected/reward states absent |
| Content | Fish drop IDs 001–003, low-grade vial/scrap and Snakehead inherited scene exist; other ten drops and three monster types absent |
| FLAC | Leaf objective has no obtainable daun_residue resource/source; dialogue strings serialized but undeclared |
| Persistence | No gameplay save/load service; pause save button is a TODO |

Implementation decisions, measured results and limitations are recorded below after verification.

## Implemented migration

- Existing FLAC `.tres` definitions are unchanged, preserving UIDs, quest IDs, objective IDs, numeric enums, prerequisites, descriptions and XP/currency. The four paths remain in `flac-database.tres`.
- Bunga now drops `daun_residue`, repairing the previously unobtainable leaf objective; Pohon keeps its existing bark source. Existing user edits to bark/test loot are retained. FLAC NPC assignment uses the established faculty and stable NPC IDs; original characters/timelines/art remain.
- Serialized resource dialogue fields are now declared and used. NPC reward callbacks delegate to the manager; repeated old callback paths are harmless. Room setup establishes identity before parenting and protects both ACTIVE and COMPLETE quests from room reset.
- Legacy ActiveQuest wraps QuestInstance rather than maintaining a second evaluator. The obsolete pickup-side ItemQuestComponent cannot award objective credit before acquisition. Legacy trusted notification APIs remain for callers, but normal systems use confirmed events.
- Inventory add/pickup report actual accepted amounts. Existing partial-stack behavior becomes explicit; crafting uses an atomic removal/addition plan so failed output capacity does not destroy ingredients. Existing effect/economy values are retained, including the low-grade vial's zero mana restoration.
- Ten exact Bakau definitions, thirteen obtainable monster-drop items, four source profiles, researcher board, reactive journal and supported persistence are implemented. New visuals/icons, enemy stats and drop rates are provisional and documented, not attributed to the spreadsheet.
- Original Enemy V2 already processed explicit `extra_drops`; this task preserves that behavior and uses independent Bakau entries. Guaranteed/zero probabilities now explicitly bypass inappropriate random endpoints.
- No production Bakau campaign map is invented. The dedicated playable field lab is the integration entry point. The reusable board is ready to place in a future world scene.

## Validation and results

All four FLAC acceptance/progression/reward flows and all ten Bakau flows pass actual-system integration. Exact IDs, rewards, prerequisites and source mappings are checked. Save/load and separate-process source/PCK restore pass. Existing Magis and Enemy suites remain green. Measured suite totals, commands, logs, rendered UI evidence and limitations are in [Bakau integration tests](bakau-integration-tests.md).

## Changed areas and history

Branch: `refactor/quest-pipeline-v2`, based on Enemy V2 `2cb873c`.

- `e2f5e36`: compatible resource schemas and exact Bakau quest catalogue.
- `622de9e`: thirteen monster drops, four shared Enemy V2 source profiles and native visuals.
- `96bed1e`: event routing/evaluation, runtime state, acquisition, rewards and persistence.
- `02e9ff1`: NPC/FLAC integration, reactive quest journal, field board/lab, pause save and crafting transaction integration.
- `75274a6`: quest/loot tests, real dialogue/pickup checks, restart/PCK verification, chain recovery and resource-only monster-drop registration.
- The documentation commit completes the eight reference guides; use `git log 2cb873c..HEAD --oneline` and `git diff 2cb873c..HEAD --stat` for the complete committed list.

Core paths: `autoloads/quest-manager.gd`, `autoloads/inventory-manager.gd`, `components/quests/`, `components/quest-manager/quest-instance.gd`, `components/NPCs/`, `components/loot/dropped-item/`, Magis event hooks, `data/quests/`, `data/items/`, `data/loot/bakau/`, `data/npc/enemies/`, `scenes/ui/quest-ui/`, `scenes/tests/bakau-quest-test.*`, `tests/quest-*`, `tools/test-quests.py` and the eight quest/drop documents.

Pre-existing changes to player data, Physics spell resources, two loot resources, Dialogic vendor modules, project settings and FLAC hallway scene are excluded from these commits. No push, merge or modification of main was performed.

## Explicit limits

Authority/owner isolation is implemented; complete multiplayer replication, remote inventory and party progress are not. Persistence covers quest/inventory/reward state rather than full world state. Branch storage is implemented without branching dialogue/UI. Held/delivery authoring should use explicit item IDs; event matching supports explicit tags/metadata. Delivery allocation detects ambiguous overlaps safely but is not a general set solver. Receipt history has no compaction policy yet. Native visuals, reused item icons and Dragonfly ground movement need production art/navigation work. Existing resource-leak/UID warnings are reported, not repaired by unrelated changes.

## Mandatory accessibility, decision and messaging extension

This extension preserves the four FLAC quest definitions, the ten Bakau definitions, all thirteen drops and their rewards. It adds grounded/access-validated spawn policies and authored markers to the three FLAC F2 rooms, gives npc.gd sole physics movement ownership, bounds wandering and chooses one unobstructed interaction focus. NPCs retain natural body layering while markers/prompts render independently. Room slots replenish after despawn, and pending offers cannot be borrowed from a different giver. Live NPCs refresh their restored instance after loading.

Natural Dialogic introduction completion no longer accepts a quest. The shared native offer panel uses a manager-issued single-use token for explicit Accept, Decline or Dismiss. Decline is reofferable by default and has Resource-authored NPC responses. Reaction dialogue yields visibility/input back to the existing Dialogic installation; no addon internals are changed. Original FLAC scene dialogue/characters/assets remain intact. Selected QuestData narrative takes precedence over generic NPC lines that describe unrelated materials. The legacy auto_accept_next flag remains serialized but no longer bypasses the explicit decision.

QuestUI is now the embedded phone messaging app. The in-world board's discoverable/locked catalogue moved to QuestCatalogue; all offer actions open the same card. QuestConversationStore persists stable contacts, actual decisions, meaningful lifecycle messages, optional snapshots and read state in an optional v2 field. Historical bubbles/cards are read-only; reward claims remain centralized. Existing item icons are used, with native SVG XP/currency symbols and the existing NPC sprite fallback where needed.

Pre-existing edited Enemy Resources had omitted identity fields. Small schema compatibility getters recover enemy identity from the canonical quest identity/registered filename, AI action identity from its kind and standalone ability identity from its filename, without replacing those edited Resources. Full fresh export exposed an unused generic talking-NPC template referencing a missing old story timeline; it now uses the existing FLAC greeting. Generated export conversion cache is cleared by packed verification so old binary conversions cannot silently strip added dialogue fields.

New reference documents: quest-dialogue-ui.md, quest-conversation-model.md and npc-spawn-accessibility.md. The updated test report records 940 source assertions and 273 packed repetitions with zero failures, including all 90 accessibility/UI checks, plus an actual rendered run and eight inspected screenshots. All testing is on the current working tree with preserved pre-existing edits; a separately clean checkout is not claimed.

Additional commits:

- `0f914bf`: compatible identity recovery for edited Enemy Resources.
- `e3c2c00`: accessible NPC placement/movement/focus, explicit native offers and persistent phone conversations.
- `092c733`: all-fourteen offer coverage, real dialogue/phone input tests, giver association, nonquest greeting repair and source/PCK restart verification.
- The documentation commit adds the final guides; use `git log 6fba0e8..HEAD --oneline` for the complete extension history.

Remaining boundaries are conservative authored floor routes rather than arbitrary jump/navmesh planning, transient offer UI/cooldown policy, no history compaction, provisional portraits/item art where no final asset exists, and the previously documented multiplayer/world-save limits. No push or merge was performed.
