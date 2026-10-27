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
