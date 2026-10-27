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
