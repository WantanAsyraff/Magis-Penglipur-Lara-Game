# Quests and objectives

## Definitions and runtime services

Schemas: [QuestData](../../data/quests/quest-data.gd), [QuestObjectiveData](../../data/quests/quest-objective-data.gd), [QuestObjectiveGroup](../../data/quests/quest-objective-group.gd), [QuestDatabase](../../data/quests/quest-database.gd). Author files under data/quests/ in faculty/content folders. [bakau-database.tres](../../data/quests/bakau-database.tres) and the Bakau quest Resources are practical references. QuestRegistry resolves/validates definitions; QuestManager owns local QuestInstance state; QuestConversationStore owns messages/read receipts; QuestRewardService owns claim/transaction behavior.

## Editor walkthrough: defeat a new enemy and collect its item

1. Complete the new enemy and item/drop registration first. EnemyManifest must expose the enemy_id and the death observer must publish the same identity (set quest_enemy_id accordingly). Register the item directly or through loot on that registered enemy.
2. FileSystem → data/quests/<content>/ → New Resource → QuestData. Save a unique file, set quest_id, title, description, faculty, region_id and optional pool_id/tags/type. Faculty enums retain existing numeric values; choose in Inspector rather than copying a number blindly.
3. In objectives create two New QuestObjectiveData subresources. First objective_id `defeat_sentinel`, type DEFEAT_ENEMY, target_id `study_sentinel`, required_amount 3. Second objective_id `collect_sample`, type COLLECT_ITEM, target_id your registered new item's ID, required_amount 2, collection_mode DELIVERY if the hand-in consumes the samples. These are hypothetical exercise IDs, not shipped definitions.
4. Give descriptions matching actual requirements. Leave requires_objectives empty to allow both concurrently. To require collecting **after** the kills, set the second's requires_objectives [defeat_sentinel]. One event uses a snapshot of eligible objectives; it will not complete a prerequisite and its dependent in the same event.
5. Mark optional objectives with is_optional. For alternative routes create QuestObjectiveGroup, give group_id and Policy.ALL/ANY, then set corresponding group_id on objectives. ANY minimum_completed must be satisfiable by nonoptional members. An optional group is not mandatory for overall completion. Avoid overlapping delivery allocations; the service safely refuses ambiguous unsatisfied removal plans rather than fabricating items.
6. Set prerequisite_quest_ids and optional next_quest_id to registered IDs, and hand_in_npc_id to the real giver. Add nonnegative reward_xp/reward_currency. For reward_items, New LootData with registered ItemData, equal positive min/max quantities and no extra_drops. Rewards do not roll drop_chance. Optional registered reward_spells and boolean reward_flags extend the same transaction.
7. Write dialogue_offer, dialogue_incomplete, dialogue_complete and accepted/declined reactions. Do not implement acceptance or rewards in a Dialogic timeline-ended callback. Narrative completion opens the explicit offer card; only Accept commits acceptance. auto_accept_next is retained legacy metadata and does not automatically accept a chained quest.
8. Add the QuestData to an already loaded database's quests array (FLAC or Bakau). To use an entirely new database, add its path to QuestRegistry's constructor and validate the complete registry. Assigning it only to a QuestBoard does not make it authoritative registered quest content.
9. To create a board, add an Area2D to your room and attach components/quests/quest-board.gd (or add the registered QuestBoard node class). Its ready method creates the detector/collision/label. Assign database, matching region_id and npc_id; or configure a QuestNPCComponent with matching faculty and NPCPresentation. An NPC selects available quests by faculty, not by an invented per-NPC quest_id export. Use a board's database list when explicit browsing is desired.
10. In an isolated session, inspect locked prerequisites, view offer, decline, reoffer and explicitly accept. Kill via the normal damage/death route, acquire real pickups, verify held/removal changes, hand in at the correct NPC and verify exact rewards once. Repeat hand-in and replay a receipt: no second reward. Save/load in fresh process and PCK, checking conversations and tracked quest as well as quantities.

## Objective semantics and property map

| Property/mode | Meaning |
| --- | --- |
| objective_id | Stable unique within quest; saved progress key, not item ID |
| target_id + target_ids | Deduplicated target union; exact event IDs |
| target_tags | Any matching event tag can satisfy cumulative event targeting; metadata requirements still all apply |
| match_metadata | Every configured key/value must match event metadata |
| CUMULATIVE | Count confirmed acquisitions after acceptance; samples need not remain held |
| CURRENT_HELD | Reconcile currently held explicit item IDs; can become incomplete after removal |
| DELIVERY | Held reconciliation plus validated removal on claim; use explicit item IDs, not tag-only delivery |
| despawn_after_seconds | Offer/NPC-instance despawn timer parameter; not the active quest expiry |
| expires_after_seconds | Opt-in active wall-clock quest expiry; 0 means no expiry |
| repeatable / prerequisites / next quest | Repeatability and dependency graph; reward ledger still guards each instance |
| selected_branch storage | Runtime persistence support exists; there is no full authored branching-dialogue UI |

The objective enum includes TALK_TO_NPC, COLLECT_ITEM, DEFEAT_ENEMY, REACH_LOCATION, SPELL_CAST, SPELL_HIT, STATUS_APPLIED, OBJECT_INTERACTED, QUEST_COMPLETED, WORLD_FLAG_CHANGED and DIALOGUE_COMPLETED. [Event integration](../quest-event-integration.md) maps exact publishers. Location/object integration needs a QuestWorldEvent Area2D with a collision shape and target_id, or a deliberate confirmed action publisher; it is not generated by the objective Resource.

## Persistence, validation and failure diagnosis

QuestRegistry checks identity, cross-references, objective/group satisfiability, cycles and fixed rewards. Runtime progress/claims belong to QuestInstance/QuestManager, never mutable QuestData. All authoritative quest/inventory/XP/currency/claim/receipt state is in the one Quest V2 bundle inside Save V1. Hand-in stages delivery and additions, commits the full autosave synchronously, then emits notifications/outbox; failed storage rolls back the reward transaction. Historical chat is read-only and cannot accept or claim.

Common failures are unregistered databases/IDs, wrong owner/event target, incomplete acceptance, unsatisfied objective order, missing item acquisition or wrong hand-in NPC. Finishing a dialogue is deliberately insufficient. Use [troubleshooting](../reference/troubleshooting.md) and quest-pipeline/quest-persistence/quest-accessibility plus new content tests; those suites contain fixed shipped catalogue expectations, not automatic verification of every new quest.

Completion: all definitions registered; live giver/publishers obtainable; explicit decisions work; requirements and exact rewards match text; failed capacity/storage/replay cases tested; history/receipts/source/PCK/fresh-process restore checked.
