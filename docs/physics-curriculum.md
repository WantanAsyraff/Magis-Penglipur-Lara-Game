# Physics curriculum

Current authoring: [academic guides](authoring/courses-and-subjects.md) and [spells](authoring/spells.md). The measured 4.6 results below remain historical; current project setup requires 4.7.

Implemented: **12 subjects, 42 spells**, preserving all eight legacy resource paths, UIDs, IDs and directional sequences. Course ID remains `sc-stem-0001`; existing PHY-001 / PHY-002 paths and UIDs remain stable.

## Progression

| Subject | Topic | Prerequisites | Spells |
| --- | --- | --- | --- |
| PHY-001 | Classical Mechanics I | None | Force, Strike, Crash |
| PHY-002 | Oscillations and Wave Mechanics | PHY-001 | Resonate, Shatterwave, Collapse, Terminal |
| PHY-003 | Kinematics and Momentum | PHY-001 | Vector Reversal, Inertia Vault, Impact Prism, Momentum Anchor |
| PHY-004 | Rotational Dynamics | PHY-003 | Angular Vortex, Torque Lock, Gyroscopic Shield |
| PHY-005 | Thermodynamics | PHY-001 | Kinetic Chill, Thermal Bloom, Entropy Leak, Heat Engine |
| PHY-006 | Electromagnetism | PHY-003 | Static Arc, Faraday Cage, Magnetic Tether, Induction Grid |
| PHY-007 | Optics and Photonics | PHY-002 | Refraction Beam, Total Internal Reflection, Prism Split, Optical Trap |
| PHY-008 | Fluid Mechanics | PHY-003 | Pressure Jet, Buoyancy Field, Vortex Well |
| PHY-009 | Material and Structural Physics | PHY-004 | Elastic Barrier, Brittle Fracture, Structural Fabrication, Resonance Threshold |
| PHY-010 | Acoustics and Harmonic Physics | PHY-002 | Sonic Pulse, Harmonic Stabilization, Phase Cancellation |
| PHY-011 | Quantum-Inspired Mechanics | PHY-005, PHY-007 | Tunneling Step, Probabilistic Echo, Decoherence Trap |
| PHY-012 | Relativity and Advanced Field Theory | PHY-006, PHY-011 | Gravitational Lens, Gravitational Well, Time Dilation Zone |

The graph branches after Mechanics I. Structural Physics, Fluid Mechanics and Acoustics are optional for reaching the expert core. PHY-012 requires Electromagnetism and Quantum-Inspired Mechanics; the latter requires Thermodynamics and Optics. Explicit completion and purchase-once XP accounting reuse `Player_Global_Data`, tested for all twelve subjects. The existing spell-tree depth layout, edges, lock signals and scroll sizing work with the new DAG; interactive panning and label readability require visual review. The original curriculum change introduced no separate save format; current Save V1 persists these purchases and comprehension.

## First-pass balance model

- Novice through expert baseline cost is 15 / 20 / 25 / 30 mana, with legacy costs retained (12–55). This is a content baseline, not a damage-per-mana equivalence rule. Preparation is generally 0.1 / 0.2 / 0.3 / 0.4 s; cooldown 1 / 1.5 / 2 / 2.5 s. Terminal has a 6 s cooldown. Force remains inexpensive with useful knockback; higher tiers add control combinations and utility rather than uniformly higher damage.
- Status duration is generally 1–5 s. Resonance caps at three independent stacks. Slow uses the strongest active factor rather than multiplying multiple slows. Thermal shock consumes cooling; fracture consumes brittle; wave finishers consume resonance.
- Typical area radius is 130–200 px; area ticks 0.2–1 s; area lifetime 3–5 s. Traps last 8–10 s and trigger once on the first eligible occupancy. Constructs last 4 s, or 8 s for fabrication. Solid constructs are 150 × 16 px and placement rejects existing terrain overlap.
- Projectile ranges preserve legacy 800–2000 px, with new Static Arc at 950 px. Cast target selection is bounded to 500 px by default. World aim placement uses 220 px or the smaller target range. Vector impulses are clamped; additive collision-aware motion lasts 0.25 s.
- Pressure Jet channels for 2 s, spending 5 mana/s after its upfront cost. It applies repeated force while channeling. Interruption stops further delivery; costs of already dispatched payloads are not refunded.
- Static Arc visits at most three additional targets, with 0.75 falloff per jump. Echo is a paid half-damage / half-healing replay with a 64-effect budget. It replays only simple projectile, self, direct or burst payloads; it cannot replay triggers, conditional effects, summons, fields, chains, or another echo. Eligible copied statuses retain their configured duration and magnitude.
- Shared execution remains bounded to 256 effects and depth eight per context; resource cycles fail validation. Per-caster persistent area / beam / trap / construct count is capped at twelve. Beam paths are capped at five configured outputs and four segments each. Triggers have at most six required hits and a 30 s lifetime; reapplication replaces the same spell trigger on a target.

No sustained balance playthrough or frame-time benchmark was performed. In dense encounters, exhausting a context effect budget intentionally ends its field early. Broad performance claims are unverified.

## Interactive laboratory

Run `res://scenes/spell-testing/physics-curriculum-lab.tscn` in Godot 4.7. The scene contains the production Player, stationary/moving dummies, a three-target cluster, structural/magnetic bodies that reset on defeat, floor and raised platform, a solid wall, an optical interface and an initially resonating target. The selector exposes all 42 spells. F6 casts the selected spell through Player; F7 resets targets; F8 refills mana. Native movement controls remain available. O toggles casting stance; CHAINED executes exact completions immediately; I/J/K/L input directions; P clears the current sequence; bind the separate cancel_casting action in Settings to interrupt active casting. Direct spells choose the nearest eligible target in the aim cone. All spells are learned/equipped only for that runtime session.

For visuals, cast every selector entry and compare its described outcome in the [catalogue](physics-spell-catalogue.md). Verify cast/activation flashes, colour-coded areas, beam paths, trap cross markers, construct boundaries, duration arcs and status indicators. Move the caster to test all aim directions; use the cluster for area/chain behavior. Fabricate a platform over open traversal space and stand on it until expiry. Position a beam against the wall and the right-hand -45° optical interface. Run the [interaction recipes](physics-spell-interactions.md). These visual/manual procedures are reproducible but have not been completed by a human tester.

## Historical executed verification

Engine: Godot **4.6.1 stable Linux x86_64**, downloaded to `/tmp/magis-godot` because no Godot binary was on PATH. Existing local project.godot autoload-UID edits were preserved. The source and packed checks used the working tree, including the six pre-existing local edits; these edits are excluded from curriculum commits.

```sh
python3 tools/test-physics.py --godot /tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64
```

Actual results: editor import exit 0; regression **71 checks, 0 failures**; curriculum **272 checks, 0 failures**; Physics lab headless startup / 120-frame smoke exit 0. No parse, missing-resource or runtime script errors. The runner rejects script errors and missing/short completion summaries even when Godot exits zero. Logs are written to `/tmp/magis-physics-*.log`.

```sh
GODOT=/tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64
$GODOT --headless --editor --path . --export-pack Web /tmp/magis-physics.pck
cd /tmp
$GODOT --headless --main-pack /tmp/magis-physics.pck res://tests/physics-curriculum.tscn
$GODOT --headless --main-pack /tmp/magis-physics.pck res://tests/spell-regression.tscn
```

Pack export completed. Outside the source directory, packed curriculum: **272 checks, 0 failures**; packed regression: **71 checks, 0 failures**. This verifies Godot packed resource remapping, not browser/WebAssembly deployment. `git diff --check` passed. No justfile is present.

The existing Dialogic shutdown diagnostics remain: 25 resources still in use and ObjectDB instances leaked. Earlier V2 documentation already identifies these vendor-resource leaks. Stale unrelated asset UIDs also fall back to valid paths. These warnings are not treated as a warning-free result, and the runner reports them explicitly.

## Mechanics and limits

See the [implementation matrix](physics-implementation-coverage.md) and [interaction tests](physics-spell-interactions.md). New reusable components are VectorEffect / SpellMotionImpulse, ProjectileFieldEffect, ChainEffect, TriggerEffect / SpellHitTrigger, InterruptEffect, ReplayEffect, SpellConstruct and native feedback nodes. Existing delivery, statuses, conditional children, damage/heal, stat effects, spawn effects, teleport, casting costs and progression are reused and extended. Beam delivery now performs bounded terrain raycasts and configured optical turns/reflections. This is a 2D puzzle rule, not a full optical medium simulation.

All gameplay changes retain server-only execution. Client casting requests, replication and reconciliation remain absent as documented in V2. Consequently networked spell play is incomplete. Save V1 now persists academic completion and comprehension; historical curriculum verification below predates it. Graphical playthrough, UI navigation ergonomics, controller aim, sustained performance, competitive balance and browser export are unverified.

Branch: `feature/physics-curriculum-expansion`, based on V2 commit `0dc1f76`. Implementation commits before final tests/docs: `e6b91b4`, `b2a9ef6`, `727ff4b`, `96d4cfb`, `0ee5726`; final tests/docs commit is the branch HEAD. Existing unrelated working-tree edits were left uncommitted.
