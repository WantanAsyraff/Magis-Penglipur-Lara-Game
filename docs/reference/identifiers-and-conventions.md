# Identifiers, folders and GDScript classes

Use explicit unique gameplay IDs on new content. Current content mixes hyphens/underscores; preserve released spell/item/enemy/quest/subject IDs exactly. New scene IDs should follow the registry's lowercase_underscore convention. New filenames generally use kebab-case; retain existing case-sensitive paths such as Enemy.tscn, EnemySpawner.tscn and NPC-quest-spawner.tscn.

| Identifier | Scope / consequence |
| --- | --- |
| field_id | Academic identity and comprehension key |
| course_id | Authored course identity; not a valid subject prerequisite by itself |
| subject_id | Completed academic purchase, prerequisite and full-save allowlist |
| spell_id | Spell library, authorization, cooldowns, quests and learned/equipped save references |
| enemy_id / quest_enemy_id | Registered enemy type vs published kill identity; align for quest objectives |
| ability_id / action_id | Loadout/action-local IDs, cooldown/filter keys; explicit IDs avoid fallback filename/kind collisions |
| item_id | Registry/inventory/acquisition/save identity; multiple distinct ItemData under same ID cause conflicts |
| quest_id / objective_id | Definition/reward ledger identity vs per-quest saved progress key |
| instance_id / event_id | Runtime UUID-like quest instance and receipt identity; do not reuse/prune without transaction policy |
| npc_id / dialogue_identity | Persistent giver/contact/event key vs portrait/timeline presentation selector |
| scene_id | Trusted registry destination; save JSON does not execute arbitrary scene paths |
| checkpoint_id | Stable authored safe respawn identity |
| Godot UID | Asset resolver identity in .tres/.tscn/.uid, separate from gameplay keys |

Create assets through the Editor so new files get their own UID. Move existing files through FileSystem to preserve identity and update references. Inspect generated ext_resource paths/UIDs in Git. Never copy an old Resource UID to make a new gameplay definition or “fix” a save by renaming only a file.

`class_name` registers a GDScript type in the Resource dialog/code parser. Exact names matter: subjectData is lowercase-leading; SpellData and EnemyData are not interchangeable with Node classes such as Boss or ActiveEffectManager. Academic “class” means a subject/course in these guides. No character-class Resource system exists; Player_Global_Data.p_role is a string.

Read [the schema](resource-reference.md) and [registration matrix](content-registration-matrix.md). Resource placement is a convention plus a few explicit scans, not a universal dynamic plugin system. Released identifiers, enum ordering, objective requirements and persistent scene/node paths need the [save evolution review](../architecture/save-load-architecture.md).
