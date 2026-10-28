# Content completion checklists

## Every content change

- [ ] Read actual schema and canonical guide, inspect a real example.
- [ ] Assign explicit stable IDs, meaningful presentation and correct typed dependencies.
- [ ] Confirm required vs conditional fields and all validator bounds; review dormant fields.
- [ ] Make shared Resources unique only when a per-variant change is intended.
- [ ] Register through the actual manifest/database/scene; review generated paths.
- [ ] Make content reachable/obtainable in normal intended gameplay.
- [ ] Add focused behavior/reference assertions; run relevant existing suites and inspect logs.
- [ ] Test actual visuals, collision, timing, interaction and balance manually or state limits.
- [ ] Export a fresh PCK and exercise the new references there.
- [ ] Check save identity compatibility in isolated fresh-process writer/reader fixtures.
- [ ] Update handbook/schema reference with public schema/registration changes.

## Family-specific gates

| Family | Additional completion checks |
| --- | --- |
| Field/course/subject | Course UI route, prerequisite DAG, explicit comprehension source, once-only purchase, learned vs equipped distinction, save course allowlist |
| Spell/effect/status | No exact duplicate combos; shared prefix intentional; cost/queue/interrupt/authority; target acceptance; bounded nested effects; classification/expiry/stack/clear; no new prediction panel |
| Enemy/profile/ability | Matching role/action/loadout, reachable range, mana/LOS, no shared HP/cooldown state, safe spawn, one death/loot/kill event |
| Boss | Ordered thresholds, usable weighted pools, telegraph/damage geometry, phase/interruption/death/exit/retry cleanup and campaign isolation |
| Item/loot/recipe | Registry identity, stack/capacity and accepted quantity, probability vs fixed reward, actual obtainable source, transaction and pickup-effect distinction |
| Quest/NPC | Correct event targets/owners, explicit Accept/Decline, approachable giver, valid groups/order, correct hand-in, fixed rewards, claim/outbox replay protection and phone read history |
| World/tutorial | Trusted SceneData/baked paths, exactly one player, correct marker convention, arrival/return paths, full ground clearance, modal input restoration, raw assets retained in export |

Tests are evidence of the specific referenced content and cases they exercise. A passing preexisting suite does not automatically validate a new enemy never instantiated by it, or establish visual balance.
