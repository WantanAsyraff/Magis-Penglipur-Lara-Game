# Campaign save system V1

Current handbook entry: [authoring/architecture guide](architecture/save-load-architecture.md). Schema defaults and current source remain authoritative; any dated test paragraphs below retain their original verification scope.

`SaveManager` coordinates the existing player, spell library, world/scene registry, Inventory_Manager and QuestManager. QuestSaveService still owns the single authoritative representation of quests, inventory, equipment, XP, currency, learned spells, claims, acquisition receipts, conversations, processed events and durable outbox. None of those values are duplicated elsewhere in the full-game payload.

## Profiles and schema

Three profiles each own `user://campaign-v1/profile-N-manual.json` and `profile-N-auto.json`. Each has a `-backup.json` previous-good sibling. Test mode uses `test-profile-N-*` exclusively. Autosave never overwrites a manual file. New Game confirms replacement of BOTH destinations and copies existing files to timestamped `.replaced-*` archives before its initial write. It replaces the manual primary atomically, then removes the prior autosave only after the new manual save succeeds. A failed initial write preserves the existing primary and reports a gameplay dialog. Load Game deletes only the explicitly confirmed destination and its backup, preserving the other destination and profiles. Continue initially selects the newest valid save and displays actual metadata.

Files are JSON envelopes:

```json
{"payload":"<serialized full-game JSON>","sha256":"<SHA-256 of exact payload text>"}
```

The payload contains:

| Field | Meaning |
| --- | --- |
| `version` | Full-game schema version 1; unsupported versions are refused |
| `profile`, `slot` | Profile 1–3 and `manual` / `auto` |
| `meta` | Character name, Unix UTC timestamp, elapsed unpaused campaign seconds |
| `player` | Name/role/mood, level, current/max health and mana, field/major/minor, completed subject IDs, comprehension ranks, ordered equipped spell IDs, dungeon keys, scene combat mode and phone availability |
| `quest` | Unmodified Quest V2 authoritative subsystem bundle |
| `location` | Trusted registered campaign scene ID, position pair, facing ±1 |
| `checkpoint` | Stable checkpoint ID, registered scene ID, safe position pair and facing |

Spells resolve exclusively through Spell_Library IDs. Equipped IDs must be unique and learned. Completed subject IDs resolve against the current authored Physics course; add future authored courses to `GameSaveSchema.COURSES`. Scene paths never come from user JSON. Only registry-provided campaign ZoneRoot scenes may initialize a saved session; menus and training rooms are rejected. Inventory quantities, health, mana, XP, currency, quest timestamps/progress, claims, world flags and collection sizes are bounded and validated before live mutation. JSON floating-point representations of integral values are accepted only when exactly integral.

Assistant preferences and keybindings remain in their existing separate configuration files. Current world/location labels derive from the restored scene's authored registry entry.

## Restoration transaction

1. Read a bounded file, parse its envelope, verify integrity, parse the payload and validate schema/identifiers.
2. Use QuestSaveService staging to resolve inventory, quests, conversations, reward/event receipts and learned Resources. Resolve equipped spell Resources and the trusted destination scene.
3. Instantiate the destination before replacing anything. Keep the prior scene, player references and progression available for rollback.
4. Pause gameplay; suppress quest publication, expiry, acquisitions and autosave. Close transient dialogue/offer UI, detach the prior scene, clear runtime NPC registration and stage authoritative state.
5. Add the destination and wait for its existing ZoneRoot to initialize the one local player. Do not create an extra player or restore position before this occurs.
6. Reapply staged progression after authored setup; clear cast queues, temporary effects, velocity, invincibility and input locks. Restore position/facing and camera smoothing. If a position intersects solid world collision, use a valid authored PlayerSpawn; if no safe fallback exists, roll back.
7. Rebuild derived UI, restore control, mark the session ready and dispose of the old scene. If initialization fails, restore the retained prior scene and progression.
8. Resume the existing durable reward outbox with stored event IDs and repair an interrupted committed next-quest offering. This is recovery of already committed transactions; load does not synthesize acquisitions or repeat rewards.

Scene-entry story scripts skip automatic intro dialogue during restoration. New Game initializes actual defaults (level 1, 9999 XP, 400 health/mana, empty inventory/spells/academics/quests), uses the opening scene's authored spawn and writes an initial manual save before starting its introduction. Test mode skips that introduction. Deferred QuestManager bootstrap no longer auto-loads the legacy file. There are no competing startup loaders.

## Checkpoints, autosave and death

Quest completion/hand-in and safe campaign scene entry request a coalesced 0.5 second autosave. An authored PlayerSpawn becomes an entry checkpoint when available; scenes without a valid marker retain the previous checkpoint. `components/save/checkpoint.tscn` provides an Area2D with a Respawn marker and stable exported checkpoint ID for explicit checkpoints. Activation requires the local player, no solid overlap at the proposed coordinate, and supporting ground within 240 world units. Place markers away from hazards. Opening-scene PlayerSpawn is authored at (220, 760).

Dead players, incomplete initialization, menu/test/prototype scenes, unsupported network sessions, active writes, failed loads and partially committed rewards cannot trigger ordinary saves. A successful reward claim performs a synchronous full-game **autosave** inside QuestRewardService's existing commit/rollback boundary, before reward notifications. Its failure invokes the existing full reward rollback. Claim persistence remains mandatory in normal campaigns.

Death loads a valid autosave, falling back to the manual save, and respawns at its recorded checkpoint with full health/mana. It never writes zero HP. With no usable save, existing main-menu routing remains available; damaged backups require explicit recovery from Load Game. The standalone boss encounter retains its own defeat/retry and temporary loadout restoration; campaign writes are blocked there.

## Durable world state and transient policy

QuestManager.world_flags remains the only flag store. WorldPersistence derives stable hashed keys from authored campaign scene path, node path and state. Collected dungeon keys, opened locked doors and broken boxes/non-respawning balloons read those flags on scene initialization and mark them during normal play. Dungeon key possession is saved separately from collection flags so consumed keys do not respawn. Renaming/reparenting an authored persistent object changes its identity and requires a future content migration.

NPC movement, enemy instances/health, dropped enemy loot, projectiles, attack callbacks, animation/movement transitions, casting sequences/queues, cooldowns, open screens, offer tokens and particle state are transient. Temporary buffs/debuffs are deliberately cleared on load and checkpoint recovery. Persistent effects are not supported in V1. Respawnable balloons and ordinary enemies follow their existing respawn behavior. Runtime IDs/registrations rebuild with scenes.

## Durability and recovery

The writer restricts destinations to one safe child filename under `user://campaign-v1/` and rejects encoded envelopes larger than 32 MB before touching a temporary or primary file. It writes a sibling `.tmp`, flushes, checks the file error, closes, preserves the prior **validated** primary as a backup via a temporary sibling, then renames the complete temporary primary over the destination. No pre-delete of the primary occurs. A write/backup failure preserves the current primary. The synchronous writer and manager guard prevent overlapping commits. Stale temporary files are ignored by discovery/loading and replaced by a later complete write; they are never promoted as saves.

SHA-256 detects accidental corruption; it is not protection against deliberate editing. Damaged or incompatible files do not mutate progression. Load Game offers explicit previous-backup loading. Damaged evidence is preserved until the user explicitly deletes or replaces that destination. After loading a backup, delete the damaged destination explicitly before saving there again. If both copies fail, choose another slot or an empty profile; neither is silently reset.

Flush/atomic rename behavior has been exercised on local Linux storage. Directory fsync, power-loss guarantees on every filesystem, asynchronous disk I/O, cloud synchronization and Web browser storage durability are outside this V1. Manual/claim writes are synchronous and can briefly wait for slow storage.

## Legacy Quest V2 import

New Game offers Import Legacy Quest V2 when a legacy file exists and the selected profile is empty. The importer reads `user://quest-progress-v2.json`, validates with QuestSaveService, wraps its exact authoritative progression into schema 1, and writes a new manual save. Claims, receipts, outbox, conversations and decisions are retained. The original legacy file is untouched and remains a recovery source. Occupied destinations are refused.

Missing legacy identity/level/academic fields, spell equipment, vitals and checkpoint data use documented new-game defaults. Learned spells/XP/currency/inventory are taken from the legacy bundle, not guessed. Missing position uses the opening scene's authored safe spawn. Import does not invent historical position, equipped spells or academic progress.

## Boundaries and verification

Campaign persistence is single-player only, including offline peers. Networked Save/Load actions are disabled with an explanation. Isolated quest-format tests retain explicit paths for their existing fixtures; production campaign UI routes through SaveManager. Standalone labs cannot overwrite the legacy default via automatic partial saves.

Unknown/retired scene, quest, item, spell or completed-subject references fail safely; there is no speculative content-ID migration. Three fixed profiles, no thumbnail system and no persistent enemy simulation are deliberate V1 boundaries. See [actual commands, results, screenshots and remaining baseline issues](combat-save-v1-verification.md).
