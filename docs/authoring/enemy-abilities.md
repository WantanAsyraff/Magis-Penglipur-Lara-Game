# Enemy abilities and attacks

[EnemyAbilityData](../../data/npc/enemies/enemy-ability-data.gd) defines one authorized loadout entry. Place reusable definitions under data/npc/enemies/abilities/. [guardian-melee.tres](../../data/npc/enemies/abilities/guardian-melee.tres) is a working effect-based example. EnemyCombat consumes abilities; basic attacks should not require copying its script.

## Inspector procedure

1. Right-click abilities/ → New Resource → EnemyAbilityData. Save a new file; set explicit ability_id unique within the enemy's loadout.
2. Select kind MELEE or SPELL and role OFFENSE/DEFENSE/HEAL/SUMMON. Role selects compatible AI actions; it is not a guarantee the payload performs that role.
3. MELEE: add effects such as DamageEffect amount 15 and KnockbackEffect force 100. Set min_range 0, max_range suitable for body root distances, requires_los, windup, recovery, cooldown and weight. These example values are hypothetical; no authored balance is changed by this guide.
4. SPELL: assign an existing valid SpellData, for example an explicitly registered Physics spell, and a range band compatible with its delivery/target_range. Choose OFFENSE for attacks, DEFENSE for a SELF buff, HEAL for actual HealEffect and SUMMON for an appropriate summon spell.
5. Add this Resource to EnemyData.abilities and ensure its EnemyAIProfile contains a matching kind/action. action.ability_id may pin it; leaving the action ID filter blank permits highest-weight usable matches.
6. Run ability.validate()/EnemyData.validate(), test the actual enemy and export its reachable definition. New abilities need no global manifest when referenced by EnemyData, but an externally referenced player spell must still be registered if it should participate in player quests/saves.

## Runtime and limits

All numeric ability timing/range/weight values must be finite/nonnegative; min_range ≤ max_range. Spell abilities delegate SpellValidator. Melee requires a nonempty valid effect list. Selection checks authority, death/hurt/stun, busy state, ability cooldown, valid live target, range, LOS and spell silence/cooldown/mana. It requires upfront plus configured full channel mana before selection; casting still checks/payment occurs through the shared service. Both ability cooldown (scaled by EnemyData.cooldown_multiplier) and SpellData.cooldown apply.

Windup is an additional EnemyCombat delay before release; a SPELL's own cast_time can then prepare it. Melee rechecks conditions at release and calls CombatRequest with source attribution; it is not a fake SpellData. Spell release uses SpellCastingComponent and normal target/team handling. Recovery follows completion/failure. Higher weight chooses a preferred eligible ability, not a probability.

SELF spell selects caster. An ALLIES healing spell selects the lowest injured compatible registered actor in range; ordinary support is not a global team command system. MELEE targets the hostile actor even if role is labelled defensive, so use an appropriate spell for self/support. requires_los uses the combat ray's terrain mask 16; perception terrain_mask does not change that hardcoded combat ray.

Common mistakes: missing action for role; weight set to zero expecting explicit disable (validation allows zero, selection still considers it); too-small max_range; double windup from ability plus spell; mana pool 0; unlearned player-only assumptions on enemy loadouts. Completion: valid exact ID, proper kind/payload/role, authorized loadout, tested interruption/cost/range/LOS and PCK dependencies.
