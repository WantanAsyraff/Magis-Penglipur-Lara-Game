# Quest save format v2

Quest V2 is now the authoritative subsystem bundle embedded in [full-game schema V1](save-system-v1.md). `user://quest-progress-v2.json` is a legacy import source, not an automatic startup load or production write destination. SaveManager owns profile selection and Pause-menu Save. Hand-in still requires a synchronous durable snapshot before reward signals; in a campaign this commits one full-game autosave through the existing reward transaction. Explicit isolated Quest V2 test paths retain the partial-format API and 0.25-second test save scheduling. `--quest-test-mode` disables automatic persistence/bootstrap, so regression suites do not modify the real play save; explicit regression saves use separate filenames.

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
| conversations (optional v2 extension) | Stable NPC contacts, display/portrait references, ordered deduplicated entries and read state |

Resources are resolved through registries rather than arbitrary save-provided file paths. Stage validates version/owner, required container types, numeric bounds, item/spell/quest references, inventory capacity/stacks, unique instance IDs, objective progress and matching handed-off/claim markers before replacing live values. Unknown schema/resource references fail without partially mutating state. This is a local save format, not a secure network message or tamper-proof economy.

The writer serializes to a sibling `.tmp`, flushes/closes it and renames it over the destination. Only bounded `user://` paths without parent traversal are accepted. If writing fails during reward delivery, inventory, receipts, XP, currency, completed IDs, learned spells, flags, outbox and claim marker roll back together. The quest remains COMPLETE with a retry message. A full inventory similarly preserves the claim. No reward is silently dropped.

Current coordinated load applies the validated staged inventory/objective snapshot without generating acquisition events or reconstructing lifecycle history; durable outbox events replay using their saved IDs. Already-processed events are ignored. A claim committed before its next-quest offering is repaired by restoring the chain if no next instance exists. Ordinary unsaved progress within the autosave window can be lost on abrupt termination; the stronger transaction guarantee specifically covers successfully committed reward claims. Atomic rename/flush behavior is tested for local Linux storage, not power-loss durability on every platform/filesystem.

## Supported boundary

This inner bundle represents quest, inventory and reward progression. The full-game envelope now supplies player, academic, equipment, scene, checkpoint and world-object restoration; see [Save system V1](save-system-v1.md). It does not restore scene/position, health, enemies/dropped objects, arbitrary NPC movement, world-object presentation, equipped spell slots or derived equipment stats. World scenes must consume restored flags. Remote player inventories and network persistence are not supplied. Starting with a different owner rejects the local file. Save V1 explicitly imports this legacy V2 format; the completed list/claims/receipts remain together. Future item/quest retirement needs explicit schema migration; unknown IDs currently reject a snapshot.

Receipt/claim histories are retained without compaction. Do not prune them independently of world-drop lifetime and persistence guarantees.

Conversation restore replaces the store and validates referenced quests/receipts without inventing missing messages. Old v2 files without conversations remain supported. Unresolved offer tokens/panels are not approvals and do not restore; live NPCs reacquire their newly loaded instance. See [conversation schema](quest-conversation-model.md).
