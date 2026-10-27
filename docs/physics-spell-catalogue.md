# Physics spell catalogue

All 42 entries are native SpellData resources registered in the export manifest and connected to exactly one subject. Every entry passed resource validation, unique-incantation resolution, and a production casting / mana / delivery check in `tests/physics-curriculum.tscn`. Focused assertions and manual visual procedures are described in the curriculum and interaction guides. Automated dispatch completion is not a claim of graphical playtesting.

Scientific principles describe the inspiration. Creature-scale force, healing, fabricated matter, optical confinement, quantum and relativistic effects are fictional mana-powered extrapolations.

## Force

- ID: `physc_force`; resource: `phys-force.tres`.
- Subject: PHY-001 — Classical Mechanics I; tier: Novice.
- Subject prerequisites: none.
- Scientific principle: Force changes momentum; F = ma for constant mass.
- Gameplay / intended interaction: Cheap kinetic hit with directional knockback.
- Delivery: Projectile.
- Effects: `Legacy damage 17 + knockback 320`.
- Mana: 12 upfront; 0 / channel second. Preparation: 0.1 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: up → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 800.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Force in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Strike

- ID: `phys-strike`; resource: `phys-strike.tres`.
- Subject: PHY-001 — Classical Mechanics I; tier: Novice.
- Subject prerequisites: none.
- Scientific principle: Momentum is mass times velocity; impulse transfers momentum.
- Gameplay / intended interaction: Fast precision projectile with large displacement and slow.
- Delivery: Projectile.
- Effects: `Legacy damage 8 + knockback 700 + slow 0.3 / 5 s`.
- Mana: 15 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: down → left → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 950.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Strike in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Crash

- ID: `phys-crash`; resource: `phys-crash.tres`.
- Subject: PHY-001 — Classical Mechanics I; tier: Novice.
- Subject prerequisites: none.
- Scientific principle: Impulse is the time integral of force.
- Gameplay / intended interaction: Heavy hit; consumes structural weakness for extra damage and stagger.
- Delivery: Projectile.
- Effects: `[["conditional", {"required_status": "brittle", "children": [["damage", {"amount": 22}], ["apply-status", {"status": "stun", "duration": 0.6, "magnitude": 0}]], "consume": true, "capability": "structural"}], ["damage", {"amount": 28}], ["knockback", {"force": 480}]]`.
- Mana: 35 upfront; 0 / channel second. Preparation: 0.25 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: up → down → up → down → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 1200.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Crash in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Resonate

- ID: `phys_resonate`; resource: `phys-resonate.tres`.
- Subject: PHY-002 — Oscillations and Wave Mechanics; tier: Novice.
- Subject prerequisites: PHY-001.
- Scientific principle: Driven oscillations near a natural frequency can grow when damping is small.
- Gameplay / intended interaction: Stacks resonance up to three times and deals bounded periodic damage.
- Delivery: Projectile.
- Effects: `[["damage", {"amount": 10}], ["apply-status", {"status": "resonance", "duration": 5, "magnitude": 1, "stacking": 2, "max_stacks": 3}], ["apply-status", {"status": "dot", "duration": 3, "magnitude": 2}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.1 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: down → left → down → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 900.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Resonate in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Shatterwave

- ID: `phys-shatterwave`; resource: `phys-shatterwave.tres`.
- Subject: PHY-002 — Oscillations and Wave Mechanics; tier: Novice.
- Subject prerequisites: PHY-001.
- Scientific principle: Superposition changes displacement; destructive interference does not destroy energy.
- Gameplay / intended interaction: Radial wave finisher consumes resonance for a mana-powered impulse.
- Delivery: Area burst.
- Effects: `[["damage", {"amount": 12}], ["conditional", {"required_status": "resonance", "children": [["damage", {"amount": 25}], ["knockback", {"force": 250}]], "consume": true}]]`.
- Mana: 22 upfront; 0 / channel second. Preparation: 0.1 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: down → left → down → left → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 180 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Shatterwave in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Collapse

- ID: `phys-collapse`; resource: `phys-collapse.tres`.
- Subject: PHY-002 — Oscillations and Wave Mechanics; tier: Novice.
- Subject prerequisites: PHY-001.
- Scientific principle: Overlapping driven waves can focus energy locally.
- Gameplay / intended interaction: Stationary interference field damages and draws targets repeatedly.
- Delivery: Persistent area.
- Effects: `[["damage", {"amount": 8}], ["vector", {"mode": 1, "strength": 70}], ["conditional", {"required_status": "resonance", "children": [["damage", {"amount": 7}]]}]]`.
- Mana: 40 upfront; 0 / channel second. Preparation: 0.1 s; channel: 0 s; cooldown: 1.0 s.
- Incantation: down → left → down → right → down → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 130 px; persistent / construct lifetime 3 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Collapse in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Terminal

- ID: `phys-terminal`; resource: `phys-terminal.tres`.
- Subject: PHY-002 — Oscillations and Wave Mechanics; tier: Novice.
- Subject prerequisites: PHY-001.
- Scientific principle: Terminal speed is a balance of driving and drag forces, not a universal maximum speed.
- Gameplay / intended interaction: Expensive long-range terminal impulse with explosive impact; unlike Collapse, it is a single moving payload.
- Delivery: Projectile.
- Effects: `[["damage", {"amount": 85}], ["knockback", {"force": 750}], ["apply-status", {"status": "slow", "duration": 2, "magnitude": 0.25}]]`.
- Mana: 55 upfront; 0 / channel second. Preparation: 0.35 s; channel: 0 s; cooldown: 6 s.
- Incantation: up → right → down → left → up → right → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 2000.0 px; area radius 200.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Terminal in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Vector Reversal

- ID: `phys-vector-reversal`; resource: `phys-vector-reversal.tres`.
- Subject: PHY-003 — Kinematics and Momentum; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Velocity is a vector; reversing it requires an impulse supplied here by mana.
- Gameplay / intended interaction: Reverses hostile projectiles and transfers hit ownership.
- Delivery: Area burst.
- Effects: `[["projectile-field", {"mode": 0}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → down → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Vector Reversal in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Inertia Vault

- ID: `phys-inertia-vault`; resource: `phys-inertia-vault.tres`.
- Subject: PHY-003 — Kinematics and Momentum; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: An impulse changes momentum; inertia alone cannot accelerate a body.
- Gameplay / intended interaction: Directional collision-safe impulse for traversal.
- Delivery: Self.
- Effects: `[["vector", {"mode": 0, "strength": 650}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → left → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Inertia Vault in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Impact Prism

- ID: `phys-impact-prism`; resource: `phys-impact-prism.tres`.
- Subject: PHY-003 — Kinematics and Momentum; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Momentum and energy conversion require an interaction and an energy budget.
- Gameplay / intended interaction: Brief armor converts the next damaging hit into a damage buff and forward impulse.
- Delivery: Self.
- Effects: `[["modify-stat", {"stat": "defense", "amount": 8, "duration": 4}], ["trigger", {"hits": 1, "duration": 4, "children": [["modify-stat", {"stat": "damage", "amount": 12, "duration": 3}], ["vector", {"mode": 0, "strength": 220}]]}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → left → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Impact Prism in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Momentum Anchor

- ID: `phys-momentum-anchor`; resource: `phys-momentum-anchor.tres`.
- Subject: PHY-003 — Kinematics and Momentum; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Damping transfers motion energy to an environment.
- Gameplay / intended interaction: Rapidly damps movement then sustains a strong slow.
- Delivery: Direct target.
- Effects: `[["vector", {"mode": 3, "strength": 0.8}], ["apply-status", {"status": "slow", "duration": 3, "magnitude": 0.75}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → left → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Momentum Anchor in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Angular Vortex

- ID: `phys-angular-vortex`; resource: `phys-angular-vortex.tres`.
- Subject: PHY-004 — Rotational Dynamics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Torque changes angular momentum about an axis.
- Gameplay / intended interaction: Rotating force field draws targets while circulating them.
- Delivery: Persistent area.
- Effects: `[["vector", {"mode": 2, "strength": 90}], ["apply-status", {"status": "slow", "duration": 1, "magnitude": 0.2}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → left → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Angular Vortex in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Torque Lock

- ID: `phys-torque-lock`; resource: `phys-torque-lock.tres`.
- Subject: PHY-004 — Rotational Dynamics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Rotational resistance opposes changes of orientation.
- Gameplay / intended interaction: Strong short movement resistance and brief casting suppression.
- Delivery: Direct target.
- Effects: `[["apply-status", {"status": "slow", "duration": 2, "magnitude": 0.85}], ["apply-status", {"status": "silence", "duration": 1, "magnitude": 0}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → right → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Torque Lock in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Gyroscopic Shield

- ID: `phys-gyroscopic-shield`; resource: `phys-gyroscopic-shield.tres`.
- Subject: PHY-004 — Rotational Dynamics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Angular momentum resists reorientation; projectile interception is magical.
- Gameplay / intended interaction: Orbiting follower construct intercepts hostile projectiles.
- Delivery: Summon / construct.
- Effects: `Expiring physical construct; interception / reflection / solid geometry follow resource configuration`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → right → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 65 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Gyroscopic Shield in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Kinetic Chill

- ID: `thermal_01`; resource: `thermal-kinetic.tres`.
- Subject: PHY-005 — Thermodynamics; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Temperature relates to microscopic energy distributions, not bulk movement.
- Gameplay / intended interaction: Cooling-themed slow marks a target for thermal shock.
- Delivery: Projectile.
- Effects: `[["damage", {"amount": 15}], ["apply-status", {"status": "slow", "duration": 3, "magnitude": 0.4}], ["apply-status", {"status": "cooled", "duration": 4, "magnitude": 0}]]`.
- Mana: 12 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: up → up → up → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 2000.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Kinetic Chill in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Thermal Bloom

- ID: `phys-thermal-bloom`; resource: `phys-thermal-bloom.tres`.
- Subject: PHY-005 — Thermodynamics; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Heat flows because of temperature differences; mana supplies heating energy.
- Gameplay / intended interaction: Visible damaging heat zone consumes cooling for one extra shock and removes the slow.
- Delivery: Persistent area.
- Effects: `[["damage", {"amount": 5}], ["conditional", {"required_status": "cooled", "children": [["damage", {"amount": 12}], ["remove-status", {"status": "slow", "remove_debuffs": false}]], "consume": true}], ["apply-status", {"status": "heated", "duration": 2, "magnitude": 0}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → up → right → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 5 s; tick 1 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Thermal Bloom in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Entropy Leak

- ID: `phys-entropy-leak`; resource: `phys-entropy-leak.tres`.
- Subject: PHY-005 — Thermodynamics; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: Entropy production accompanies irreversible processes; entropy is not a substance.
- Gameplay / intended interaction: Bounded periodic damage and mana drain against mana-capable targets.
- Delivery: Direct target.
- Effects: `[["apply-status", {"status": "dot", "duration": 5, "magnitude": 3}], ["apply-status", {"status": "mana_drain", "duration": 4, "magnitude": 2}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → up → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Entropy Leak in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Heat Engine

- ID: `phys-heat-engine`; resource: `phys-heat-engine.tres`.
- Subject: PHY-005 — Thermodynamics; tier: Intermediate.
- Subject prerequisites: PHY-001.
- Scientific principle: A heat engine converts some supplied heat to work; efficiency is bounded.
- Gameplay / intended interaction: Mana pays for a temporary regeneration and preparation-speed enhancement.
- Delivery: Self.
- Effects: `[["modify-stat", {"stat": "mana_regen", "amount": 4, "duration": 5}], ["modify-stat", {"stat": "cast_speed", "amount": 0.25, "duration": 5}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → up → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Heat Engine in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Static Arc

- ID: `phys-static-arc`; resource: `phys-static-arc.tres`.
- Subject: PHY-006 — Electromagnetism; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Electric fields exert forces on charge; discharges follow available conductive paths.
- Gameplay / intended interaction: Bounded nearest-target chain prioritizes magically charged targets.
- Delivery: Projectile.
- Effects: `[["damage", {"amount": 14}], ["conditional", {"required_status": "charged", "children": [["damage", {"amount": 6}]]}], ["chain", {"hops": 3, "amount": 10, "preferred_status": "charged"}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → up → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 950.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Static Arc in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Faraday Cage

- ID: `phys-faraday-cage`; resource: `phys-faraday-cage.tres`.
- Subject: PHY-006 — Electromagnetism; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Conducting enclosures redistribute charge; shielding depends on geometry and frequency.
- Gameplay / intended interaction: Stationary field construct intercepts hostile magical projectiles.
- Delivery: Summon / construct.
- Effects: `Expiring physical construct; interception / reflection / solid geometry follow resource configuration`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → up → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 110 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Faraday Cage in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Magnetic Tether

- ID: `phys-magnetic-tether`; resource: `phys-magnetic-tether.tres`.
- Subject: PHY-006 — Electromagnetism; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Magnetic response depends on material and charge motion.
- Gameplay / intended interaction: Marks any combat target as magically charged; pulls only explicitly magnetic bodies.
- Delivery: Direct target.
- Effects: `[["apply-status", {"status": "charged", "duration": 5, "magnitude": 0}], ["vector", {"mode": 1, "strength": 260, "capability": "magnetic"}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → down → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Magnetic Tether in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Induction Grid

- ID: `phys-induction-grid`; resource: `phys-induction-grid.tres`.
- Subject: PHY-006 — Electromagnetism; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Changing magnetic flux induces an electromotive force.
- Gameplay / intended interaction: Single-use charged entry trap with brief stun.
- Delivery: Trap.
- Effects: `[["damage", {"amount": 12}], ["apply-status", {"status": "charged", "duration": 5, "magnitude": 0}], ["apply-status", {"status": "stun", "duration": 0.7, "magnitude": 0}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → down → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 8 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Induction Grid in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Refraction Beam

- ID: `phys-refraction-beam`; resource: `phys-refraction-beam.tres`.
- Subject: PHY-007 — Optics and Photonics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Refraction changes propagation direction at an optical interface.
- Gameplay / intended interaction: Beam is blocked by terrain and turns at configured optical interfaces.
- Delivery: Beam.
- Effects: `[["damage", {"amount": 12}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → down → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 1 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Refraction Beam in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Total Internal Reflection

- ID: `phys-total-internal-reflection`; resource: `phys-total-internal-reflection.tres`.
- Subject: PHY-007 — Optics and Photonics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Total internal reflection requires a higher-index medium and incidence above its critical angle.
- Gameplay / intended interaction: Mana creates a reflective optical surface that returns hostile projectiles and eligible beams.
- Delivery: Summon / construct.
- Effects: `Expiring physical construct; interception / reflection / solid geometry follow resource configuration`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → down → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 65 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Total Internal Reflection in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Prism Split

- ID: `phys-prism-split`; resource: `phys-prism-split.tres`.
- Subject: PHY-007 — Optics and Photonics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: A prism disperses wavelengths; magical splitting pays for three output paths.
- Gameplay / intended interaction: Three bounded beam trajectories spread over a fan.
- Delivery: Beam.
- Effects: `[["damage", {"amount": 7}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → left → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 1 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Prism Split in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Optical Trap

- ID: `phys-optical-trap`; resource: `phys-optical-trap.tres`.
- Subject: PHY-007 — Optics and Photonics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Optical forces can trap small particles; confining creatures is deliberately magical.
- Gameplay / intended interaction: Entry trap briefly confines then impairs a target.
- Delivery: Trap.
- Effects: `[["apply-status", {"status": "stun", "duration": 1.5, "magnitude": 0}], ["apply-status", {"status": "slow", "duration": 3, "magnitude": 0.7}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → left → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 8 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Optical Trap in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Pressure Jet

- ID: `phys-pressure-jet`; resource: `phys-pressure-jet.tres`.
- Subject: PHY-008 — Fluid Mechanics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Pressure gradients drive fluid acceleration.
- Gameplay / intended interaction: Continuous directional displacement during a mana-charged interruptible channel.
- Delivery: Beam.
- Effects: `[["vector", {"mode": 0, "strength": 110}], ["knockback", {"force": 80}]]`.
- Mana: 20 upfront; 5 / channel second. Preparation: 0.2 s; channel: 2 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → left → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 2.5 s; tick 0.2 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Pressure Jet in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Buoyancy Field

- ID: `phys-buoyancy-field`; resource: `phys-buoyancy-field.tres`.
- Subject: PHY-008 — Fluid Mechanics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Buoyancy is the net pressure force on a displaced fluid volume.
- Gameplay / intended interaction: Lifts allies and enemies locally for traversal and control.
- Delivery: Persistent area.
- Effects: `[["vector", {"mode": 4, "strength": 160}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → left → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 4.0 s; tick 0.2 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Buoyancy Field in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Vortex Well

- ID: `phys-vortex-well`; resource: `phys-vortex-well.tres`.
- Subject: PHY-008 — Fluid Mechanics; tier: Intermediate.
- Subject prerequisites: PHY-003.
- Scientific principle: Converging fluid flow carries momentum toward a sink.
- Gameplay / intended interaction: Pure grouping field without damage, cheaper than advanced gravity.
- Delivery: Persistent area.
- Effects: `[["vector", {"mode": 1, "strength": 110}]]`.
- Mana: 20 upfront; 0 / channel second. Preparation: 0.2 s; channel: 0 s; cooldown: 1.5 s.
- Incantation: right → right → up → down → right → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 4.0 s; tick 0.25 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Vortex Well in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Elastic Barrier

- ID: `phys-elastic-barrier`; resource: `phys-elastic-barrier.tres`.
- Subject: PHY-009 — Material and Structural Physics; tier: Advanced.
- Subject prerequisites: PHY-004.
- Scientific principle: Elastic deformation can store energy and return part of an impact.
- Gameplay / intended interaction: Solid temporary reflective surface doubles as a platform.
- Delivery: Summon / construct.
- Effects: `Expiring physical construct; interception / reflection / solid geometry follow resource configuration`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → right → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 60 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Elastic Barrier in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Brittle Fracture

- ID: `phys-brittle-fracture`; resource: `phys-brittle-fracture.tres`.
- Subject: PHY-009 — Material and Structural Physics; tier: Advanced.
- Subject prerequisites: PHY-004.
- Scientific principle: Brittle materials fracture with little plastic deformation.
- Gameplay / intended interaction: Marks a target; Crash consumes the mark only on structural-capable objects.
- Delivery: Direct target.
- Effects: `[["apply-status", {"status": "brittle", "duration": 5, "magnitude": 0}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → right → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Brittle Fracture in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Structural Fabrication

- ID: `phys-structural-fabrication`; resource: `phys-structural-fabrication.tres`.
- Subject: PHY-009 — Material and Structural Physics; tier: Advanced.
- Subject prerequisites: PHY-004.
- Scientific principle: Structures transmit loads through their geometry and constituent materials.
- Gameplay / intended interaction: Creates a temporary solid platform for traversal; mana supplies fictional matter.
- Delivery: Summon / construct.
- Effects: `Expiring physical construct; interception / reflection / solid geometry follow resource configuration`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → down → right → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0 px; persistent / construct lifetime 8 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Structural Fabrication in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Resonance Threshold

- ID: `phys-resonance-threshold`; resource: `phys-resonance-threshold.tres`.
- Subject: PHY-009 — Material and Structural Physics; tier: Advanced.
- Subject prerequisites: PHY-004.
- Scientific principle: Repeated driving can accumulate response when losses are sufficiently small.
- Gameplay / intended interaction: On the third damaging impact, consumes resonance for structural damage and stagger.
- Delivery: Direct target.
- Effects: `[["trigger", {"hits": 3, "duration": 6, "children": [["conditional", {"required_status": "resonance", "children": [["damage", {"amount": 35}], ["apply-status", {"status": "stun", "duration": 1, "magnitude": 0}]], "consume": true, "capability": "structural"}]]}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → left → up → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Resonance Threshold in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Sonic Pulse

- ID: `phys-sonic-pulse`; resource: `phys-sonic-pulse.tres`.
- Subject: PHY-010 — Acoustics and Harmonic Physics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Sound is a propagating pressure disturbance in a medium.
- Gameplay / intended interaction: Radial pressure impulse interrupts nearby spell preparation and channels.
- Delivery: Area burst.
- Effects: `[["knockback", {"force": 350}], ["interrupt", {}], ["apply-status", {"status": "silence", "duration": 0.5, "magnitude": 0}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → left → up → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Sonic Pulse in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Harmonic Stabilization

- ID: `phys-harmonic-stabilization`; resource: `phys-harmonic-stabilization.tres`.
- Subject: PHY-010 — Acoustics and Harmonic Physics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Oscillations can be controlled by feedback; biological healing here is entirely magical.
- Gameplay / intended interaction: Self-heal and targeted removal of destabilizing statuses.
- Delivery: Self.
- Effects: `[["heal", {"amount": 22}], ["remove-status", {"status": "resonance", "remove_debuffs": false}], ["remove-status", {"status": "slow", "remove_debuffs": false}], ["remove-status", {"status": "stun", "remove_debuffs": false}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → left → up → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Harmonic Stabilization in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Phase Cancellation

- ID: `phys-phase-cancellation`; resource: `phys-phase-cancellation.tres`.
- Subject: PHY-010 — Acoustics and Harmonic Physics; tier: Advanced.
- Subject prerequisites: PHY-002.
- Scientific principle: Opposite-phase coherent waves can cancel displacement locally, without erasing energy.
- Gameplay / intended interaction: Purges eligible wave statuses and cancels hostile wave-tagged projectiles and areas.
- Delivery: Area burst.
- Effects: `[["remove-status", {"status": "resonance", "remove_debuffs": false}], ["remove-status", {"status": "dot", "remove_debuffs": false}], ["projectile-field", {"mode": 3}]]`.
- Mana: 25 upfront; 0 / channel second. Preparation: 0.30000000000000004 s; channel: 0 s; cooldown: 2.0 s.
- Incantation: right → right → up → left → up → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Phase Cancellation in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Tunneling Step

- ID: `phys-tunneling-step`; resource: `phys-tunneling-step.tres`.
- Subject: PHY-011 — Quantum-Inspired Mechanics; tier: Expert.
- Subject prerequisites: PHY-005, PHY-007.
- Scientific principle: Quantum tunneling concerns barrier transmission amplitudes, not human teleportation.
- Gameplay / intended interaction: Fictional short displacement; conservative swept collision check rejects obstructed paths.
- Delivery: Self.
- Effects: `[["teleport", {"distance": 160}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → down → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Tunneling Step in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Probabilistic Echo

- ID: `phys-probabilistic-echo`; resource: `phys-probabilistic-echo.tres`.
- Subject: PHY-011 — Quantum-Inspired Mechanics; tier: Expert.
- Subject prerequisites: PHY-005, PHY-007.
- Scientific principle: Quantum probabilities do not permit copying arbitrary states; this echo is fictional.
- Gameplay / intended interaction: Paid replay of the last compatible simple payload at half damage; cannot replay itself.
- Delivery: Self.
- Effects: `[["replay", {}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → down → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 0.0 px; persistent / construct lifetime 4.0 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Probabilistic Echo in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Decoherence Trap

- ID: `phys-decoherence-trap`; resource: `phys-decoherence-trap.tres`.
- Subject: PHY-011 — Quantum-Inspired Mechanics; tier: Expert.
- Subject prerequisites: PHY-005, PHY-007.
- Scientific principle: Decoherence suppresses observable interference through environmental entanglement.
- Gameplay / intended interaction: Fictional entry-triggered disruption trap with damage and casting suppression.
- Delivery: Trap.
- Effects: `[["damage", {"amount": 18}], ["apply-status", {"status": "silence", "duration": 2, "magnitude": 0}], ["apply-status", {"status": "slow", "duration": 2, "magnitude": 0.5}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → down → left. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 150.0 px; persistent / construct lifetime 10 s; tick 0.5 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Decoherence Trap in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Gravitational Lens

- ID: `phys-gravitational-lens`; resource: `phys-gravitational-lens.tres`.
- Subject: PHY-012 — Relativity and Advanced Field Theory; tier: Expert.
- Subject prerequisites: PHY-006, PHY-011.
- Scientific principle: Gravity can bend light trajectories; magical fields also bend these projectiles.
- Gameplay / intended interaction: Curves hostile projectile trajectories within a visible local region.
- Delivery: Persistent area.
- Effects: `[["projectile-field", {"mode": 1, "radius": 180, "strength": 0.3}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → down → right. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 180 px; persistent / construct lifetime 4.0 s; tick 0.2 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Gravitational Lens in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Gravitational Well

- ID: `phys-gravitational-well`; resource: `phys-gravitational-well.tres`.
- Subject: PHY-012 — Relativity and Advanced Field Theory; tier: Expert.
- Subject prerequisites: PHY-006, PHY-011.
- Scientific principle: Gravity accelerates matter toward concentrations of mass-energy.
- Gameplay / intended interaction: Strong grouping field; heated targets receive additional compression damage.
- Delivery: Persistent area.
- Effects: `[["vector", {"mode": 1, "strength": 140}], ["apply-status", {"status": "compressed", "duration": 1, "magnitude": 0}], ["conditional", {"required_status": "heated", "children": [["damage", {"amount": 4}]]}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → left → up. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 200 px; persistent / construct lifetime 4.0 s; tick 0.4 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Gravitational Well in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.

## Time Dilation Zone

- ID: `phys-time-dilation-zone`; resource: `phys-time-dilation-zone.tres`.
- Subject: PHY-012 — Relativity and Advanced Field Theory; tier: Expert.
- Subject prerequisites: PHY-006, PHY-011.
- Scientific principle: Relativistic proper-time differences are physical; this zone uses fictional selective local modifiers.
- Gameplay / intended interaction: Locally slows hostile movement and projectile speed without changing Engine time scale.
- Delivery: Persistent area.
- Effects: `[["apply-status", {"status": "slow", "duration": 0.5, "magnitude": 0.6}], ["projectile-field", {"mode": 2, "radius": 180, "strength": 0.35}]]`.
- Mana: 30 upfront; 0 / channel second. Preparation: 0.4 s; channel: 0 s; cooldown: 2.5 s.
- Incantation: right → right → up → left → left → down. Chained casting is the default; completed incantations trigger automatically and support prefix continuations.
- Spatial / lifecycle bounds: range 500.0 px; area radius 180 px; persistent / construct lifetime 4.0 s; tick 0.2 s.
- Verification: production cast passed in source and exported PCK. Reproducible manual case: select Time Dilation Zone in the Physics lab, cast with F6, and verify the gameplay outcome above. Graphical appearance and game balance remain unverified by human playtesting.
