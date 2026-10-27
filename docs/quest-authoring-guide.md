# Quest authoring guide

## Add a quest with Resources

1. Duplicate a resource under `data/quests/bakau/` or the appropriate faculty directory. Keep the QuestData script, assign a new `quest_id`, title, narrative, faculty, region and pool. Do not recycle released IDs or change enum ordering. Existing numeric faculty 2 remains FLAC; faculty 6 is Technology & Science.
2. Add typed `QuestObjectiveData` subresources with unique stable `objective_id`, description, type, target ID(s), and positive required amount. Register item, enemy, spell or prerequisite references first. NPC/location/object/status/flag strings are project integration keys and must match publisher configuration.
3. For an any-combination sample, set one objective's `target_ids` to several item IDs. For separate requirements, create separate objectives. Default cumulative acquisition counts only after acceptance and never consumes samples. Set `collection_mode` explicitly for held or delivery requirements. Use explicit item IDs for held/delivery; tag matching is intended for event-based objectives.
4. Mark optional objectives `is_optional`. Set `requires_objectives` for ordering. Add `QuestObjectiveGroup` entries and matching `group_id` values for ALL/ANY routes. ANY uses `minimum_completed`. Avoid ambiguous overlapping delivery alternatives.
5. Set prerequisite quest IDs, optional next quest and auto-accept policy, hand-in NPC ID and rewards. Use registered ItemData and LootData reward entries with equal minimum/maximum quantities and no extra bundle items. XP/currency must be nonnegative. Reward probabilities are not rolled. Reward spells and flags are optional extensions.
6. Set offer/incomplete/complete dialogue. A configured timer is optional; the Bakau catalogue has none. The selected-branch field is storage, not an authored branching dialogue engine.
7. Add the Resource to a `QuestDatabase.quests` array and make that database reachable through QuestRegistry. For an existing loaded database no script change is needed. Give a QuestBoard that database/region and its configured NPC ID, or use an existing faculty QuestNPCComponent. Place the board and event publishers in a playable scene.
8. Run `python3 tools/test-quests.py --godot /path/to/godot --packed`. Add behavior assertions for the new content; the current suite deliberately asserts the shipped catalogue has fourteen entries.

## Objective/event mapping

| Objective | Event |
| --- | --- |
| TALK_TO_NPC (0) | NPC_INTERACTED |
| COLLECT_ITEM (1) | ITEM_COLLECTED; held/delivery also reconcile ITEM_REMOVED |
| DEFEAT_ENEMY (2) | ENEMY_DEFEATED |
| REACH_LOCATION (3) | LOCATION_REACHED |
| SPELL_CAST (4) | SPELL_CAST |
| SPELL_HIT (5) | SPELL_HIT |
| STATUS_APPLIED (6) | STATUS_APPLIED |
| OBJECT_INTERACTED (7) | OBJECT_INTERACTED |
| QUEST_COMPLETED (8) | QUEST_COMPLETED |
| WORLD_FLAG_CHANGED (9) | WORLD_FLAG_CHANGED |
| DIALOGUE_COMPLETED (10) | DIALOGUE_COMPLETED |

`target_id` plus `target_ids` form a deduplicated union. Event objectives can match an exact ID or any explicitly configured tag, then require every `match_metadata` entry. A world flag objective normally sets metadata `value = true`; otherwise any published change matches. Objective/quest prerequisite cycles, unknown registered references, invalid quantities and malformed rewards are registry errors. Registry diagnostics block test success; they should be corrected before shipping.

## Add a drop/source with Resources

Create ItemData with a stable ID, name, description, category, stack settings and optional existing texture/effects. Create LootData with the item, probability in [0,1], min/max quantity and rarity. Add each independent entry to an already registered EnemyData `loot` array. QuestRegistry registers all items referenced by those loot tables (including explicit bundles), so adding a monster drop requires Resource edits alone and the EnemyData reference retains it in export. Register standalone items not reachable from a monster in `data/items/item-manifest.gd`. `extra_drops` means an explicit bundle sharing that entry's successful roll; it is not an independent table. A probability of 1 is guaranteed and 0 never drops.

Register the canonical enemy definition in `data/npc/enemies/enemy-manifest.gd`. Duplicate an inherited Enemy V2 scene, assign its EnemyData, visual scene, collision dimensions and ground-sensing placement. Existing enemy archetype/resources supply AI, targeting, Magis abilities, damage, death and loot; no new monolithic script is required. Check the actual world death location, physical pickup, exact kill ID and chance/quantity bounds. A new Resource without an obtainable source is not completed content.
