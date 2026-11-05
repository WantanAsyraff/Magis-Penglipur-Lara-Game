# Modular Environmental Destruction V1 — handover

Implemented on `feature/modular-environment-destruction-v1`, based on the local main checkout. No push or merge was performed. Engine verification used installed Godot **4.7.2**, matching the project's **4.7 / GL Compatibility** configuration. Tests and exports were executed, not inferred from generated files.

## Architecture and authoring surface

One StaticBody2D shell composes durability/lifecycle, visuals, a hitbox adapter, an environmental target adapter and a typed interaction receiver. Eight `.tscn` presets select configuration/material/state/behavior Resources. A world-owned DestructionRuntime schedules delayed, ordered work and owns transient consequences. The [component hierarchy, exported configuration, public methods, signal signatures and lifecycle](../../authoring/destructible-environments.md) are documented in the core guide.

Inspector configuration groups:

| Definition/component | Authored values |
|---|---|
| DestructibleConfig | ID/name/enabled; max health/initial damage/invulnerability/multiplier; auto destruction/collision/removal/visual duration; material; typed states and behaviors; persistence ID/health/respawn policy |
| DestructibleMaterialDefinition | Five typed damage multipliers, minimum break force, knockback resistance, hit/break sound and particle scenes |
| DestructibleStateDefinition | Unique ID, threshold, texture/frames/animation, tint/transform, collision/interaction permissions, transition sound/particles |
| VisualRoot | Native placeholder geometry/size/color, fallback texture/frames, optional hook-name map and exposed Sprite2D/AnimatedSprite2D/AnimationPlayer/audio children |
| DestructionBehavior subclasses | Independently typed explosion, projectile, hazard, actor, loot, scene or event parameters; enable and pre-execution delay |
| DestructionTargetPolicy | Player/enemy/environment opt-ins, friendly fire and terrain LOS |
| SpellData | Explicit environmental_damage_kind, defaulting to IMPACT for existing assets |

Damage state selection is the lowest qualifying health threshold, with reverse transitions on repair. Destruction is immediate/idempotent for gameplay eligibility; visual completion and ordered behavior completion are distinct. Missing animations cannot hold objects alive forever. Scripted destruction follows the same lifecycle, including zero-health objects with auto-destruction disabled. State/resources never hold per-instance durability, hit lists or timers.

## Implemented consequences and integrations

- Radial explosions use body bounds, optional falloff Curves, terrain LOS, faction filtering, real hitbox damage and existing knockback. A shared event budget bounds environmental propagation.
- Shrapnel uses swept physics queries, four deterministic distribution modes, optional gravity/piercing, real damage and bounded cleanup.
- Persistent fields have bounded ticks/duration/fade. The poison preset deals direct periodic damage; optional statuses use supported existing handlers with explicit refresh/once policies and no STACK mode.
- SpawnActor installs optional EnemyData before readiness and preserves the normal Enemy V2 AI/stats/abilities/death/XP/quest/loot pipeline. Collision-aware placement is bounded; faction overrides use private Resource copies.
- LootDrop creates ordinary DroppedItem instances. Only validated pickup publishes inventory acquisition/quest semantics. Pickup delay is now a backward-compatible DroppedItem export, with the old .2-second default.
- SpawnScene creates bounded replacements/debris and propagates destruction ownership into new destructibles. SignalEvent exposes an authored signal plus closed, typed world-flag/actuator/receiver actions.
- DamageEffect uses the new virtual `HitboxComponent.receive_spell_damage`; the default forwards unchanged damage/source semantics. DestructibleHitbox captures the spell classification for the component. The existing SpellExecutor acceptance checks and delivery code remain unchanged.
- Neutral objects use the existing EnvironmentalTarget; Q remains hostile selection and R selects props. Inspection found the baseline's environment-target input action missing despite its consumer; the action was registered with R and added to remapping settings. The previously failing existing environment selector check now passes.
- Persistent object state uses existing Boolean world flags, with 24 health bits (0.01 HP precision), dead/present markers and globally stable authored IDs. No new save schema/file or migration is required. Loading a broken object does not emit destruction or replay consequences.

See [behavior exports, target rules and extension API](../../authoring/destruction-behaviors.md) and [explosive recipes](../../authoring/explosive-destructibles.md), including **How to Create a New Explosive Barrel in Under Five Minutes**.

## Working content

All eight scenes are under `components/environment/destruction/presets/`: wooden-crate, glass-barrier, stone-block, fragile-platform, explosive-barrel, poison-canister, fragmentation-container and minion-pod. They use six material presets and the shared animation library. The pod's .45-second pre-spawn delay follows its .4-second breakup, then its root is removed after consequences start. None has a per-prop gameplay script.

Run [Destruction Lab](../../../scenes/spell-testing/destruction-lab.tscn), or use F9 from the existing Physics lab. It has all eight objects and twelve chained barrels, real floor/platform collision, the actual Player/casting pipeline and available authored Force/Strike/Resonate/Shatterwave spells. R/O/IJKL remain normal input; optional debug F6 casts Force, F7 rebuilds stations, F8 refills, F9 toggles overview and F10 returns to Physics. No campaign world placements or mandatory story gates were changed.

## Executed validation

Latest successful results per suite, counted once:

| Suite | Checks | Failures | Evidence |
|---|---:|---:|---|
| Destruction framework, source | 111 | 0 | [framework.txt](framework.txt) |
| Fresh-process Save V1 writer | 3 | 0 | [save-write.txt](save-write.txt) |
| Fresh-process Save V1 reader | 4 | 0 | [save-read.txt](save-read.txt) |
| Spell Pipeline V2 regression | 71 | 0 | [spell-regression.txt](spell-regression.txt) |
| Enemy Pipeline V2 | 138 | 0 | [enemy-pipeline.txt](enemy-pipeline.txt) |
| Existing environmental interactions | 83 | 0 | [environment-interactions.txt](environment-interactions.txt) |
| Quest pipeline/inventory integration | 172 | 0 | [quest-pipeline.txt](quest-pipeline.txt) |
| Destruction framework, exported PCK | 111 | 0 | [packed-framework.txt](packed-framework.txt) |
| **Total** | **693** | **0** | **582 source/save + 111 packed** |

Editor import and Web-preset PCK export also completed. The first packed run found implicit target-policy Resources missing from converted preset Resources; presets now explicitly reference the policy, and the final source and packed suites both pass. A fresh-process writer/reader exercised the actual SaveManager campaign save/load, partial durability, already-destroyed restoration, no replayed explosion and an old-schema snapshot without destruction flags.

Coverage includes all presets, five material classes, thresholds/repair/clamping, invulnerability/disablement, missing assets/animation fallback, repeated hits, separate lifecycle events, collision/reset, real direct/area/beam/projectile paths, ordinary Player/Enemy damage, normal enemy death/XP, delayed explosions, LOS/radius/falloff/knockback/factions, physical/piercing fragment hits, lifetimes, status refresh/expiry/once policy, normal minion definitions and blocked placement, ordered/combined behaviors, real loot pickup receipts, typed world events, 12-barrel propagation, budget exhaustion, generation reset, queued/removed owners, scene unload, duplicate persistent IDs and client authority rejection.

Commands:

```bash
# Linux Flatpak; the runner gives every run isolated user/save directories.
python3 tools/test-destruction.py --flatpak --packed --regressions

# Native executable equivalent.
python3 tools/test-destruction.py --godot /path/to/godot --packed --regressions

# Actual renderer (requires a display).
flatpak run org.godotengine.Godot --path . tests/environment-destruction/preview.tscn -- --quest-test-mode
```

The runner rejects SCRIPT ERROR lines and unsuccessful assertion summaries even when Godot returns zero. Existing project shutdown ObjectDB/resource/RID diagnostics are retained in logs and explicitly distinguished from test failures. No live multiplayer replication session was performed; authority is exercised with a real non-server ENet peer. Existing broader campaign/UI tests not listed here were not newly run for this feature.

## Visual verification and performance observations

The actual GL renderer generated **22 PNGs: eleven each at 1280×720 and 1920×1080**. Dimensions were checked from the generated files. The driver uses production casting authorization and actual projectile collisions, not injected success responses. For readable three-hit states, it makes an Inspector-equivalent private **50 HP crate with loot disabled for the visual stages** and casts the unmodified authored Force spell. HUD is hidden for inspection captures; the ordinary Player/casting scene remains active.

| Stage | 1280×720 | 1920×1080 |
|---|---|---|
| Eight intact presets | [PNG](../../previews/environment-destruction/1280x720/01-all-presets.png) | [PNG](../../previews/environment-destruction/1920x1080/01-all-presets.png) |
| Damaged | [PNG](../../previews/environment-destruction/1280x720/02-damaged.png) | [PNG](../../previews/environment-destruction/1920x1080/02-damaged.png) |
| Critical | [PNG](../../previews/environment-destruction/1280x720/03-critical.png) | [PNG](../../previews/environment-destruction/1920x1080/03-critical.png) |
| Break | [PNG](../../previews/environment-destruction/1280x720/04-break.png) | [PNG](../../previews/environment-destruction/1920x1080/04-break.png) |
| Destroyed | [PNG](../../previews/environment-destruction/1280x720/05-destroyed.png) | [PNG](../../previews/environment-destruction/1920x1080/05-destroyed.png) |
| Explosion | [PNG](../../previews/environment-destruction/1280x720/06-explosion.png) | [PNG](../../previews/environment-destruction/1920x1080/06-explosion.png) |
| Shrapnel | [PNG](../../previews/environment-destruction/1280x720/07-shrapnel.png) | [PNG](../../previews/environment-destruction/1920x1080/07-shrapnel.png) |
| Poison cloud | [PNG](../../previews/environment-destruction/1280x720/08-poison.png) | [PNG](../../previews/environment-destruction/1920x1080/08-poison.png) |
| Enemy minions | [PNG](../../previews/environment-destruction/1280x720/09-minions.png) | [PNG](../../previews/environment-destruction/1920x1080/09-minions.png) |
| Cloud expired | [PNG](../../previews/environment-destruction/1280x720/10-poison-expired.png) | [PNG](../../previews/environment-destruction/1920x1080/10-poison-expired.png) |
| Bounded chain | [PNG](../../previews/environment-destruction/1280x720/11-chain-reaction.png) | [PNG](../../previews/environment-destruction/1920x1080/11-chain-reaction.png) |

Reviewed representative intact/damaged/critical/break/explosion/fragment/cloud/minion/chain captures at both sizes. Native translucent fields/rings leave characters and terrain visible; placeholder projectile artwork and the existing player casting aura remain apparent. These are development assets, not final art.

In the final capture run, the 12-barrel layout broke **10 barrels** before its default depth-8 propagation cutoff, with no recursive failure. The automation's sampled physics frame was **3.161 ms (720p)** / **1.763 ms (1080p)**. Sampled whole process time was **70.763 / 53.964 ms** while rendering/capturing in this environment; elapsed time including casts, capture and fixed waits was **1814 / 1817 ms**. These observations are not a sustained-FPS guarantee or an isolated destruction benchmark. The dedicated automated 12-barrel test raises its test context depth to 16 and confirms all twelve and exactly twelve budget reservations. Production defaults remain bounded.

## Limits and deliberate reload policies

- Default chain: 32 consequence-bearing destructions, depth 8 and 128 spawns. Runtime: 64 queued jobs, 256 active nodes and 32 behavior executions/frame. Area queries return at most 128 eligible targets. Per-resource safety limits are documented in the behavior guide.
- Spawned enemies/hazards/fragments/replacements/drops are transient, scene-owned and not reconstructed from saves. Permanent broken objects never regenerate uncollected drops; use existing durable quest/inventory rewards for essential items. Saves do not replay a pending fuse or attempt transactional respawn of delayed consequences.
- Placement checks collisions with bounded upward retries; it does not prove navmesh reachability, solve falling platforms, simulate stress or rescue actors from an authored pit.
- Static destructibles support material impulse reactions without becoming a full rigid-body simulation. TileMaps and per-pixel terrain are unchanged.
- Network authority safeguards are present; new multiplayer destruction replication is not implemented. Server-side effects do not imply replicated visual/spawn state.
- Resource definitions are trusted authored code. Custom subclasses must follow the bounded spawn/context contract; arbitrary script exceptions are not sandboxed.
- Visual prototypes are intentionally geometric. Optional tracks/particles/sounds must be replaced/tuned by content authors. State collision and gameplay do not wait on missing artwork.

## Files and next authoring step

[files.md](files.md) contains the exact new and modified file manifest, including UIDs and captured artifacts. Core additions are under `components/environment/destruction/`; integration changes are limited to the hitbox damage hook, optional pickup delay, explicit spell classification, missing R registration and lab navigation. The three authoring guides are the API/Inspector reference. To create a new destructible now, inherit a preset, make Config unique, replace its state art/material and compose the desired behavior Resources. No per-object controller is required.
