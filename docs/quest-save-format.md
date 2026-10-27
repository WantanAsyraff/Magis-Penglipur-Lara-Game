# Quest save format v2

The supported file is `user://quest-progress-v2.json`, version 2, for `QuestManager.active_owner_id` (default `local`). Deferred startup restores an existing matching snapshot. Quest/inventory mutations schedule a short 0.25-second coalesced save; hand-in requires a synchronous durable snapshot before reward signals. Pause-menu Save and field-lab F9/F10 call the same service. `--quest-test-mode` disables automatic persistence/bootstrap, so regression suites do not modify the real play save; explicit regression saves use separate filenames.

## Payload

| Field | Meaning |
| --- | --- |
| version / owner_id | Schema and active-owner guard |
| instances | Resource quest ID, UUID instance ID, owner, status, per-objective progress, NPC ID, accepted/completed times, accepted prerequisites, reward marker, pending reason, branch, offer-despawn time |
| completed_quests | Stable handed-in quest IDs used by prerequisites |
| claims | Instance-keyed owner/quest ledger |
| selected_quest | Tracked instance ID |
| seen_events | Owner plus event-receipt deduplication history |
| world_flags / pending_events | Retained world flags and durable event outbox |
| inventory / equipment | Registered item IDs and quantities; equipped IDs by slot |
| acquisition_receipts / max_slots | Confirmed acquisition deduplication and capacity |
| player_xp / currency | Progression values in same reward snapshot |
| learned_spells | Registered spell IDs |

Resources are resolved through registries rather than arbitrary save-provided file paths. Stage validates version/owner, required container types, numeric bounds, item/spell/quest references, inventory capacity/stacks, unique instance IDs, objective progress and matching handed-off/claim markers before replacing live values. Unknown schema/resource references fail without partially mutating state. This is a local save format, not a secure network message or tamper-proof economy.

The writer serializes to a sibling `.tmp`, flushes/closes it and renames it over the destination. Only bounded `user://` paths without parent traversal are accepted. If writing fails during reward delivery, inventory, receipts, XP, currency, completed IDs, learned spells, flags, outbox and claim marker roll back together. The quest remains COMPLETE with a retry message. A full inventory similarly preserves the claim. No reward is silently dropped.

On load, inventory/held objectives reconcile; durable outbox events replay using their saved IDs. Already-processed events are ignored. A claim committed before its next-quest offering is repaired by restoring the chain if no next instance exists. Ordinary unsaved progress within the autosave window can be lost on abrupt termination; the stronger transaction guarantee specifically covers successfully committed reward claims. Atomic rename/flush behavior is tested for local Linux storage, not power-loss durability on every platform/filesystem.

## Supported boundary

This is quest, inventory and reward progression persistence, not a whole-world save. It does not restore scene/position, health, enemies/dropped objects, arbitrary NPC movement, world-object presentation, equipped spell slots or derived equipment stats. World scenes must consume restored flags. Remote player inventories and network persistence are not supplied. Starting with a different owner rejects the local file. There was no prior gameplay save schema to migrate; the existing completed-quest list is retained in the bundle. Future item/quest retirement needs explicit schema migration; unknown IDs currently reject a snapshot.

Receipt/claim histories are retained without compaction. Do not prune them independently of world-drop lifetime and persistence guarantees.
