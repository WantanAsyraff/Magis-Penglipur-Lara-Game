# Monster drop catalogue

All thirteen IDs resolve to ItemData, are included in the item manifest, and are attached to their intended functional Enemy V2 source. Seeded production loot rolls demonstrate every mapped item can spawn; real delayed physical overlap demonstrates pickup. New icons reuse the existing leaf placeholder; final item art remains pending. Fish UIDs, IDs, existing effects and sale values are preserved. All source descriptions match the supplied sheet.

**Rates below are provisional implementation choices, not spreadsheet values.** Each entry rolls independently once per death. Quantities are uniformly selected within the successful entry's range. No quest boosts, pity rule or guaranteed quest samples are added.

| ID | Item | Category | Source | Chance | Quantity | Rarity | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| drop_001 | Fish Meat | Food | Snakehead Murrel | 65% | 1–2 | Common | Functional |
| drop_002 | Fish Bone | Material | Snakehead Murrel | 35% | 1–1 | Uncommon | Functional |
| drop_003 | Fish Scales | Material | Snakehead Murrel | 55% | 1–2 | Common | Functional |
| drop_004 | Dragonfly Scales | Material | Dragonfly | 60% | 1–2 | Common | Functional |
| drop_005 | Dragonfly Wings | Material | Dragonfly | 50% | 1–1 | Common | Functional |
| drop_006 | Dragonfly Antenna | Material | Dragonfly | 30% | 1–1 | Uncommon | Functional |
| drop_007 | Crab Shell | Material | Stone Crab | 65% | 1–2 | Common | Functional |
| drop_008 | Crab Claw | Weapon Material | Stone Crab | 35% | 1–1 | Uncommon | Functional |
| drop_009 | Crab Stone | Rare Material | Stone Crab | 8% | 1–1 | Rare | Functional |
| drop_010 | Crab Meat | Food | Stone Crab | 55% | 1–2 | Common | Functional |
| drop_011 | Crocodile Scales | Material | Crocodile | 60% | 1–2 | Common | Functional |
| drop_012 | Crocodile Fangs | Weapon Material | Crocodile | 25% | 1–1 | Uncommon | Functional |
| drop_013 | Crocodile Teeth | Material | Crocodile | 55% | 1–2 | Common | Functional |

## Canonical sources

| Monster | Canonical ID | Profile |
| --- | --- | --- |
| Snakehead Murrel | enemy_mangroove_snakehead_murrel | 100 HP; mobile melee; original scene UID/path retained |
| Dragonfly / Pepatung | enemy_mangroove_dragonfly | 36 HP; fast mobile defensive ranged; shared Magis seed projectile |
| Stone Crab / Ketam Batu | enemy_mangroove_stone_crab | 140 HP; slow melee, defense 5, knockback resistance 0.5 |
| Crocodile | enemy_mangroove_crocodile | 180 HP; melee, defense 3 |

Definitions: `data/npc/enemies/definitions/bakau/`. Loot entries: `data/loot/bakau/drop-001.tres` through `drop-013.tres`. Three new inherited scenes live under `components/NPCs/enemies/zalam-manifestations/bakau/`; the fish keeps its existing `fishes/snakehead-murrel.tscn` path. All use shared AI, hitbox, lifecycle, ability and loot components. Godot-native silhouette visuals and reconstructed stats are provisional. Dragonfly is mobile on the existing ground controller, not true flying navigation.

Crab Stone is 8% compared with Shell 65% and Meat 55%; its expected successful roll interval is 12.5 eligible crab deaths, with no upper bound. Required uncommon tissues use 25–35% entries. Max-2 common entries yield 1.5 items on average when successful. These rates need live play balancing; seeded tests verify reachability and bounds, not player completion-time quality.

`LootData.extra_drops` remains an explicit same-roll bundle for legacy resources. The Bakau tables use separate entries, so one successful fish roll never automatically grants all three fish items. Entries with probability 1 bypass randomness; 0 never spawns. Death and quest observer guards prevent repeated processing. Loot ownership uses the valid kill-credit owner; free/unowned drops are usable locally. Party distribution is not implemented.

No recipes are invented: all thirteen have no ingredient resources and retain default craft cost RM0. RM0 is not assigned as a sale-price rule. Existing fish economics/effects remain; new items use ItemData defaults. The low-grade vial and scrap are existing components, not additional monster-drop IDs.

## Descriptions and files

- `drop_001` — [Fish Meat](../data/items/drops/fish-meat.tres): A Kocheen's favourite meat! Used for cooking.

- `drop_002` — [Fish Bone](../data/items/drops/fish-bone.tres): Sharp, brittle bones. Used for basic needles.

- `drop_003` — [Fish Scales](../data/items/drops/fish-scales.tres): Slimy but shimmering scales.

- `drop_004` — [Dragonfly Scales](../data/items/drops/dragonfly-scales.tres): Iridescent scales that catch the light.

- `drop_005` — [Dragonfly Wings](../data/items/drops/dragonfly-wings.tres): Transparent, fragile, and incredibly light.

- `drop_006` — [Dragonfly Antenna](../data/items/drops/dragonfly-antenna.tres): Sensory organs used in perception potions.

- `drop_007` — [Crab Shell](../data/items/drops/crab-shell.tres): A hard, calcified exterior for armor.

- `drop_008` — [Crab Claw](../data/items/drops/crab-claw.tres): Sharp pincers capable of crushing.

- `drop_009` — [Crab Stone](../data/items/drops/crab-stone.tres): A rare pearl-like growth found in crabs.

- `drop_010` — [Crab Meat](../data/items/drops/crab-meat.tres): Sweet, firm meat; a delicacy.

- `drop_011` — [Crocodile Scales](../data/items/drops/crocodile-scales.tres): Rugged, thick hide for heavy defense.

- `drop_012` — [Crocodile Fangs](../data/items/drops/crocodile-fangs.tres): Long fangs that hold onto prey.

- `drop_013` — [Crocodile Teeth](../data/items/drops/crocodile-teeth.tres): Standard teeth used for primitive jewelry.

FLAC leaf support is separate: `daun_residue` is obtainable from Bunga via `data/loot/enemy-drops/daun-residue.tres` at provisional 65%, quantity 1. Pohon bark uses the existing loot resource unchanged. This is not a fourteenth master-sheet drop.
