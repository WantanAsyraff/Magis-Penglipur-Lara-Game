# Enemy Pipeline V2 migration report

## Initial audit

Started from `c40a29e` on `feature/physics-curriculum-expansion`; work proceeds on `refactor/enemy-pipeline-v2`. Magis V2 and the 42-spell Physics curriculum already exist. Ancestor AGENTS.md requires investigation, scoped edits, appropriate checks and `just verify` when available; no justfile exists. Pre-existing local changes to player data, spell/loot resources, vendor scripts, project configuration and a world scene are excluded from enemy commits.

Pohon and Bunga scenes **already exist**, with UIDs `bvvsrqdblf5ow` and `c6b3bq2x7rw7c`. History includes `0dd2250` and earlier revisions. Neither requires reconstruction. Existing Pohon is a 50-HP, 500/800-speed ranged enemy (Branch Projectile, 2.4-second attack cooldown, 500-pixel retreat threshold); Bunga is a 40-HP, 300/500-speed melee enemy (8 damage, 140-pixel melee reach, 1.5-second cooldown). Preserve these values and assets as the migration baseline rather than presenting the proposed fallback identities as historical behavior. New secondary abilities are explicitly additions.

| Area | Finding |
| --- | --- |
| Coordinator | Root combines state decisions, movement, health and lifecycle; duplicate enemy_died emission paths |
| Perception | One player reference; no factions/threat; repeated raycasts; memory does not reliably clear target |
| Combat | Ordinary melee creates fake SpellData; ranged already delegates to shared casting |
| Spawning | Deferred parenting followed by immediate global position assignment; registers unparented instances |
| Loot/quest | No once/authority guards; deferred loot may be lost when parent frees |
| Animation | Bunga's proximity-only animation component can disagree with actual AI attack state |
| Boss | Own phase system should remain; fake melee spells and ranged instances missing start(); asynchronous attacks lack cancellation guards |
| Missing resources | dudeman-test references static-bolt, rebar-lance, intrusion-ping, firewall-burst, botany; boss attack resources reference viscous-drag, thermal-siphon |
| Magis | Reuse SpellCastingComponent, SpellExecutor, SpellDelivery, HitboxComponent, ActiveEffectManager and MagicProjectile; extend context to support non-spell effect requests |

Implementation, executed tests and remaining limits are appended after validation.

## Implemented migration

### Pohon

The inherited scene and UID remain. Preserved: 50 HP, move/chase speeds 500/800, scale, tint, sprite asset, 2.4-second ranged cadence, 500-pixel retreat band, patrol range 800, jump velocity -3000 and the existing Branch Projectile resource/ID/UID. Loot still references test-loot1 and pohon-bark-sample. No historical Pohon scene was reconstructed or replaced.

Added: an explicit EnemyData, a tuned defensive-ranged AI resource and a 12-damage close strike at 200 pixels. Branch selection now respects its physical 900-pixel range instead of selecting it at the old 3000-pixel trigger distance. A `pohon` quest enemy ID is supplied explicitly; the original scene observer had no ID. This is a new usable hook, not a claimed historical event.

### Bunga

The inherited scene and UID remain. Preserved: 40 HP, move/chase speeds 300/500, original 8-damage / 140-pixel melee, 1.5-second cadence, tint, idle/attack sprite frames, patrol range 3000, jump velocity -1200, fish loot and quest enemy ID `bunga`.

Added: Seed Shot (8 damage, 4 MP, bounded projectile) and Petal Repulse (8 MP, 180-pixel burst, 280 knockback and 0.35 slow for 0.8 seconds). The balanced profile can attack, manage distance, retreat, reposition or defend with these configured abilities. The animation component follows actual state; it no longer plays attack just because a player entered an unrelated proximity area.

### Shared resources and compatibility

Six typed classes were introduced: EnemyData, EnemyStatsData, EnemyPerceptionData, EnemyAbilityData, EnemyAIProfile and EnemyAIAction. Six reusable base profiles plus two NPC-specific resource variants are authored. Three complete EnemyData resources exist (Pohon, Bunga and resource-only training guardian), along with six reusable abilities and a third-enemy SpawnData example.

Enemy's existing class, public enums, signals, health/mana/movement fields, hit API and inherited scene paths remain. Existing EnemyCombat, EnemyDetection, EnemyPatrol, animation, hitbox, loot and quest components were extended rather than duplicated. New runtime components are stats, utility AI and movement; EnemyCombat is the ability controller. EnemyDefinitionAdapter supports legacy scene exports and NPCSpellcasterData. Unused legacy mana-shield/combo/counter/spell-drop configuration stays serialized without invented behavior.

Seven missing spell definitions were recovered from `0dd2250^`: static-bolt, rebar-lance, intrusion-ping, firewall-burst, botany, viscous-drag and thermal-siphon. Their spell IDs/UIDs are retained in `data/magis/legacy-enemy-spells`, outside player spell discovery. Only the broken Dudeman/boss references are redirected. Static enemy-reference scanning reports no missing files. The training dummy's optional missing HpLabel lookup was made null-safe; its take_damage API and scene are otherwise preserved.

Ordinary attacks now use CombatRequest and the shared executor with no fabricated SpellData. All 42 Physics spells are successfully cast by a configured enemy in the suite, proving that selection is independent of delivery/effect execution. Loadout authorization denies spells not assigned to the enemy. New CombatFactions rules are consistent across direct attacks, targeting, projectile fields and construct reflection. CombatLifecycle tracks ownership and cleanup, including transfer on reflection.

Boss retains its phase controller, weighted attacks, dash motion, area warnings, burst interval, configured summon scenes and death signal. Melee/dash/AOE now use shared damage; ranged bursts use initialized shared casting. Phase resistance overrides and guarded invincibility are supported. Attack epoch checks reject late hits after cancellation. Summons and projectiles are owned and cleaned on death. Phase selection, all five attack kinds, burst initialization, summon cleanup and once-only death are exercised.

## Executed verification

Godot: **4.6.1 stable Linux x86_64**, `/tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64`. Tests ran against the working tree, including the pre-existing local edits; those edits remain excluded from these commits.

```sh
python3 tools/test-enemies.py --godot /tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64
```

| Check | Actual result |
| --- | --- |
| Static enemy resource references | Pass; no missing files |
| Headless editor import | Exit 0; no script/resource errors |
| Existing spell regression | 71 checks, 0 failures |
| Equipment UI | 38 checks, 0 failures |
| My Spells | 148 checks, 0 failures |
| Physics curriculum | 272 checks, 0 failures |
| Existing Physics laboratory startup | Exit 0 |
| Enemy integration | **138 checks, 0 failures** |
| Enemy arena headless startup, 300 frames | Exit 0; no script/resource errors |
| UID comparison against c40a29e | Base Enemy, Pohon, Bunga, two spawn resources and Branch Projectile retain all six UIDs |
| git diff --check | Pass |

Total source automated assertions: **667**. Test runners reject script errors, other resource errors, missing completion markers and nonzero exit codes; they explicitly report the existing Dialogic exit diagnostics rather than treating the project as warning-free. There is no justfile.

```sh
GODOT=/tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64
$GODOT --headless --editor --path . --export-pack Web /tmp/magis-enemies.pck
cd /tmp
$GODOT --headless --main-pack /tmp/magis-enemies.pck res://tests/enemy-pipeline.tscn
$GODOT --headless --main-pack /tmp/magis-enemies.pck res://tests/spell-regression.tscn
```

Pack export completed. Outside the source tree: enemy suite **138 checks, 0 failures**; spell regression **71 checks, 0 failures**. This is packed Godot validation, not browser/WebAssembly deployment.

A rendered arena smoke was also executed and its screenshot inspected:

```sh
$GODOT --rendering-method gl_compatibility --fixed-fps 60 --path . \
  res://scenes/tests/enemy-pipeline-test.tscn --quit-after 180 -- --capture-enemy-arena
```

Exit 0; no script/resource errors. The preview at `/tmp/magis-enemy-pipeline.png` shows player, both enemies, a Branch Projectile, target/action/cooldown labels, platforms and LOS obstacle. This verifies basic visual observability; it is not a sustained interactive combat or balance playthrough.

### Enemy coverage

| Requirement | Executed evidence |
| --- | --- |
| Data and IDs | All three definitions validate and have distinct type IDs; six base profiles validate with fourteen actions |
| Different profiles | Same body/loadout selects melee under aggressive profile and retreat under defensive profile |
| Perception | Multiple players, neutral exclusion, threat priority, occlusion, last known point, expiry, reacquisition and freed-target safety |
| Other actors | A faction-compatible NPC outside player group is detected |
| Attack lifecycle | Windup, damage amount, cooldown, release range recheck and null-spell shared execution |
| Ranged | Pohon Branch initializes, moves, ignores caster, hits hostile target and cleans up |
| Spell execution | All 42 player Physics resources execute through explicit enemy abilities |
| Resources/status | Zero mana denial, reservation/refund, silence/stun, immunity and duration resistance |
| AI movement/support | Chase, memory movement, preferred range, flee, mana recovery, repulse defense, configured cast/heal/summon, real-floor patrol and idle |
| Lifecycle | Once-only death, one quest increment, one guaranteed drop, one XP grant and owned-node cleanup |
| Spawning | Pending limit, transformed world position, both NPC scenes, death tracking, optional respawn, blocked geometry, stop cancellation and definition override |
| Boss/dummy | Melee, dash, burst, AOE, summon, phase/mitigation, late-hit cancellation, cleanup and dummy damage API |
| Instance isolation | Shared resources unchanged; actor cooldowns, threat and statuses independent |
| Authority | ENet client cannot tick perception/AI, apply damage or launch abilities; existing spell tests retain additional client denial checks |

## Known incomplete or unverified work

- Full enemy/client state, spawn, projectile and visual-event replication, late join and multiplayer reward attribution are **not implemented**. Server authority boundaries are implemented and tested; multiplayer gameplay is not claimed complete. Spawn IDs are process-global monotonic server identifiers but are not yet distributed to peers.
- Repositioning uses local platform movement/wall jumps, not full obstacle route planning.
- Sustained balance, stress/frame-time profiling, every existing world placement, browser rendering and a human interactive arena playthrough remain unverified. Existing fast movement values were preserved rather than claimed tuned.
- Legacy NPCSpellcasterData's dormant shield/probability/reaction/drop hooks remain unsupported as described above; the source resources and implemented mappings remain compatible.
- Existing Dialogic shutdown diagnostics remain: 25 resources in use and ObjectDB leaks, previously documented before this work. Stale unrelated asset UIDs may fall back to valid text paths. No new runtime resource leaks are indicated by the final counts.

## Branch and milestones

Branch: `refactor/enemy-pipeline-v2`, based on `c40a29e`. No push or merge was performed.

1. `8f6598d` — typed definitions, audit and historical spell dependency restoration.
2. `70b8bac` — spawning, reward guards and shared ordinary combat foundation.
3. `d405536` — modular perception, utility AI, stats, movement and resource profiles.
4. `e6a0388` — shared enemy/boss casting, factions and owned lifecycle.
5. `806cbfe` — migrated Pohon/Bunga resources and third-enemy example.
6. Final test/documentation commit — branch HEAD; exact hash is reported with delivery.
