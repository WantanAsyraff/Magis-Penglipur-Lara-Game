# Physics implementation coverage

Baseline: `0dc1f76` on `refactor/magis-spell-pipeline-v2`. No AGENTS.md was present in the repository. The working tree contained unrelated local edits; these are excluded from curriculum commits.

| Capability | Baseline | Curriculum implementation / verification |
| --- | --- | --- |
| Projectile, self, direct, burst | Implemented | Regression + curriculum tests |
| Persistent area, trap | Implemented, no feedback | Visible zones; bounded ticking and expiry |
| Beam | Projection only; passed through walls | Bounded ray segments, terrain occlusion, optical interfaces |
| Summon | Scene spawning only | Reusable expiring solid / intercepting constructs |
| Damage, heal, status removal, knockback, stats | Implemented | Retained; extended tagged statuses |
| Velocity modification | Missing | Reusable vector effect, projectile fields |
| Teleport | Swept body check | Retained conservative collision policy |
| Conditional children | Single status presence | Stack threshold, capability and consumption |
| Triggers | Missing | Owned damage-event trigger with count/lifetime bounds |
| Chain targeting | Missing | Nearest eligible, visited set, maximum hops |
| Echo | Missing | Paid bounded previous payload replay, no recursive replay |
| Stacking, timed statuses | Implemented | Retained maximum stacks and owner ticking |
| Reflection / deflection | Missing | Ownership transfer, collision mask and beam surfaces |
| Channeling | Charges then dispatches | Opt-in live delivery during charged channel |
| Interruption, costs, cooldowns | Implemented | Retained; Sonic Pulse invokes reusable interruption |
| Academic completion | Implemented | Twelve-subject DAG; purchase-once regression |
| Incantations | Four policies; chained default | Confirmation default; legacy chains remain opt-in |
| Multiplayer | Server-only effects; no client request/replication | Boundary retained; network play remains incomplete |

Actual verification results and limitations are recorded in physics-curriculum.md after execution. A resource property alone is not considered runtime coverage.
