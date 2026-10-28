# Physics spell interactions

> Historical implementation/verification record. The body below preserves earlier design descriptions, commands and measurements; it is not a newly executed test or the current authoring contract. Use [the current guide](authoring/spell-effects.md) and [Godot 4.7 workflow](developer-workflow.md). Current Player default is CHAINED with independent shared-prefix execution; the assistant now shows only valid next-direction icons. Save V1 supersedes earlier quest-only persistence limits.

Interactions use tagged statuses, explicit target capabilities and owned event hooks. No spell-name comparisons are used to implement combinations. `physics-curriculum.tscn` uses the real authored effect arrays and production dispatch; `spell-regression.tscn` retains validation, costs, status lifetimes, nested execution and authority tests.

| Combination | Runtime rule | Automated assertion / manual reproduction |
| --- | --- | --- |
| Resonate → Shatterwave | Resonance stacks independently, maximum three. Shatterwave applies 12 base + 25 conditional damage and knockback, consuming resonance. | Two resonance stacks are asserted, then 37 total finisher damage and status consumption. In the lab, cast Resonate twice at the stationary target, approach within 180 px and cast Shatterwave. |
| Kinetic Chill → Thermal Bloom | Cooling and slow last 4 / 3 s. The first heat tick does 5 + 12 damage, consumes cooling and removes slow; later ticks do only 5. | Authored payloads assert 17 first-tick damage and both removals. In the lab, chill a dummy then place Bloom on it. |
| Magnetic Tether → Static Arc | Tether tags a combat target as magically charged. Only a body with `magnetic` metadata is pulled. Arc adds 6 damage against charged targets and prioritizes charged chain candidates by half distance score, still within actual radius. | Tests assert charge and pull, nonmagnetic no-pull behavior, 20 primary damage and exactly three additional targets. In the lab, tether one of the cluster before casting Arc. |
| Brittle Fracture → Crash | Crash consumes brittle only when `structural` metadata is present. The conditional payload adds 22 damage + 0.6 s stun, on top of 28 base damage. | Tests assert 50 damage and stagger. In the lab, fracture then Crash a structural target. Nonstructural targets retain the tag but receive only ordinary Crash damage. |
| Vector Reversal → incoming projectile | Eligible hostile projectiles in 150 px reverse once per cast. Each gets a separate new context, defending owner/team, cleared hit history and corrected collision mask. | Tests assert direction, owner/mask and damage against the original team. Manual: use a hostile projectile source (the automated sandbox supplies one), reverse, then verify original caster can be hit. |
| Gravitational Well + Thermal Bloom | VectorEffect groups bodies; both independent areas query the resulting positions. Heated targets also receive Well's 4 conditional damage. | Tests assert inward velocity and independent thermal damage, with no combined-spell code. In the lab, layer both zones under the cluster and observe displacement and periodic damage. |
| Probabilistic Echo → previous simple spell | Successful eligible casts update per-caster history. A paid echo dispatches a new context with 0.5 damage/heal scale, a 64-effect budget and an echo guard. History excludes replay, triggers, chains, constructs and fields. | Tests assert half-damage Force, unchanged eligible history and safe refunded failure with no history. In the lab, cast Force or Terminal, then Echo. Echoed status and knockback magnitudes retain their configured values. |
| Resonance Threshold → repeated impacts | One owner-attached trigger counts positive damage events for six seconds. On the third hit, its consumed guard executes a resonance/structural conditional payoff, then deletes itself. | Test asserts the third hit adds 35 damage, consumes resonance, and a fourth hit does not trigger again. In the lab, attach Threshold, then apply Resonate and successive impacts. DOT ticks count as impacts. |
| Impact Prism → damaging hit | Four seconds of flat defense; first positive incoming damage event grants +12 damage for three seconds and a forward impulse. | Test invokes authored trigger and asserts resulting damage buff. A hit fully absorbed by armor does not trigger. |
| Sonic Pulse → Pressure Jet | InterruptEffect cancels the target's active casting component, terminates the live beam and clears queued casts. | Tests assert force before channel completion, elapsed channel cost, cancellation and no upfront refund after dispatch. |
| Total Internal Reflection → hostile beam | A solid construct is an optical interface; reflection changes direction and segment ownership to the defending caster. | Physics-frame test asserts damage returns to the hostile beam caster while the defender takes none. |
| Phase Cancellation → wave projectile / field | Explicit `has_wave_tag` eligibility; ProjectileFieldEffect CANCEL handles projectile and persistent-area groups. Selected status resources remove resonance and DOT. | Projectile cancellation asserted. Manual: place a hostile wave field in range, cast Cancellation and verify its duration indicator disappears. |

`structural` and `magnetic` are opt-in metadata capabilities on Node2D actors. Hitbox-equipped combat actors can receive statuses; arbitrary walls are not made destructible or magnetic. The lab marks its resettable structural bodies explicitly. Ordinary terrain remains solid and unaffected by fracture/status rules.

## Mechanic verification matrix

| Mechanic | Executed coverage |
| --- | --- |
| Projectile | All authored projectile casts; Force legacy adapter; terrain AOE once; reversed hit ownership |
| Self | Inertia Vault spatial displacement, Heat Engine buff, Harmonic healing, Echo |
| Direct target | All direct-resource casts, invalid target, tether capability filter, production aim picker available in lab |
| Area burst | Shatterwave cast, Vector Reversal ownership, Phase Cancellation projectile removal |
| Persistent area / area creation | Collapse/Bloom/Well casts; actual thermal damage; lifetime cleanup |
| Beam | Terrain occlusion, configured optical turn, reflected hostile ownership, three split paths |
| Trap | Induction / Decoherence actual entry damage and queued cleanup; optical trap cast |
| Summon / entity spawn | Five construct variants, expiration, physical platform collision; base SpawnEntityEffect regression |
| Damage / heal | Combination damage totals; Harmonic 22 healing; existing HoT final-boundary ticks |
| Apply / remove status | Resonance stacking, cooling/slow removal, selective Harmonic cleanse, base dispelling |
| Knockback / force | Reversed projectile, tether velocity, live pressure impulse, vault physical motion |
| Stat modification | Heat Engine magnitude and expiry; Prism event buff; base stack isolation |
| Teleport | Solid obstruction rejected; open-space destination succeeds |
| Conditional | Consumed resonance, thermal shock, structural fracture and threshold |
| Trigger / replay | Third-hit payoff once; Prism positive-damage response; bounded paid echo |
| Chain | Exactly three additional targets, no revisit; execution budgets/depth in regression |
| Channel / interruption | Live force before completion, per-second costs, Sonic cancellation |
| Decast | Selected status removal and wave projectile cancellation |
| Local time / projectile redirection | Actor slow and projectile factor, recovery, unchanged Engine.time_scale; lens heading change |
| Resource / progression | 42 valid unique resources, 12-subject DAG, all incantations confirmed without early prefix casts, each subject purchased only once |
| Lifecycle / isolation | Areas and constructs expire; contexts do not share state; queued/deleted caster and owner-ticked status checks |
| Authority | Client cannot dispatch or apply effects; remote Player damage/mana does not mutate local singleton |

## Manual review still required

Visual distinctions and readability, moving-target aiming, wall-edge collision behavior under rendering load, trap approach feedback, spell-tree panning, long-session balance, frame-time cost and browser rendering remain unverified. Multiplayer client requests and effect replication are not implemented. Headless functional results do not imply these reviews have passed.
