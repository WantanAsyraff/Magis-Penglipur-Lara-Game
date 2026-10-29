# Connected environmental puzzles

Run [Environmental Interactions Lab](../../scenes/environment-testing/environment-interactions-lab.tscn). The [authored layout](../../scenes/environment-testing/environment-lab-layout.tscn) stores every root, link and source reference in the Inspector. Stations have real floor/wall collision, a real Player, temporary equipped spells and reset controls. Number buttons are lab navigation; gameplay uses the same F/E/Q/R/O controls as the campaign.

## A — Restore power (station 02)

Fuse output → switch POWER → door ENABLE. Both fuse and switch start off; the switch initially lacks power. F at the fuse restores supply. F at the switch opens the real door collision. Turning either off closes it. Nearby, F takes the practice key from its pedestal, then F at the keyed door consumes that key. Reset restores the circuit's initial supply and switch positions.

## B — Water supply (station 04)

Source tank (100 L) → powered pump → valve → destination tank (0 L). Destination fill controls the rectangular pool surface. F at pump power and F at valve start conserved flow. The 50 kg crate floats upward and the water current carries it to an elevated pressure sensor. That plate opens the gate. The pool's right boundary keeps the crate over the sensor. Source + destination stays 100 L. Reset empties the destination, lowers the surface, restores the source and crate, and closes the gate.

This uses buoyancy and a current, not a scripted crate animation. Station 06 separately demonstrates a backed-up drain, its internal capacity and removable debris; source + channel + destination is conserved. Full blockage backpressures the source and emits overflow feedback without deleting water.

## C — School Magis practical (station 08)

Player Kinetic Chill → cooled receiver → AND relay INPUT → moving platform ENABLE. R selects the neutral receiver. Press O and enter the equipped Kinetic Chill incantation with I/J/K/L; its actual projectile and cooled status satisfy the rule. Q continues to select hostiles. Jump onto the physical platform and ride its three relative waypoints to the landing. Power interruption holds the platform and restoration resumes. Reset clears receiver progress, relay inputs and the platform route.

Station 11 expands this into two independent cooled receivers feeding one AND relay and a gate. Both are required. This architecture also supports an OR relay or inverted normally closed links without changing gameplay scripts.

## D — Controlled turret (station 09)

F at the start switch supplies turret power. The turret acquires only a hostile live actor in range and line of sight, visibly warns, then fires a production Magis projectile. Move/jump to avoid it. F at the emergency switch sends an inverted ENABLE signal, clearing windup and owned projectiles and preventing subsequent attacks. The turret is destructible and uses nonlethal direct damage; the training configuration cannot lower the player below 1 HP. Reset returns it to unpowered, clears pending attacks and restores health.

## Story placement

[House entrance](../../scenes/worlds/hubs/story/prologue/rumah-yan-entrance.tscn) instances [kampung utilities](../../scenes/environment-testing/kampung-environment.tscn): house switch/light/fan, raised tanks and pagar, tap/valve/pump, drainage and a harmless crate. Ordinary water controls work without combat. The main route and portal remain accessible.

[School practical](../../scenes/worlds/hubs/story/prologue/yan-exam-tutorial.tscn) instances [optional practical apparatus](../../scenes/environment-testing/school-environment.tscn): Kinetic Chill target, relay, raised gate/platform, practice barrier, weighted indicator and a clearly labelled opt-in nonlethal turret. The main route runs below raised mechanisms; no new mandatory challenge requires unlearned Physics spells. The original introduction still grants and equips Kinetic Chill. No Dialogic timeline, established character dialogue or story progression was edited.

Keep new integration optional until narrative gating is reviewed. Maintain clear approach distances between interactables; selection is nearest eligible, with stable ties. Leave room for the player to board a lift and for rider head clearance. Reset is a lab operation; campaign persistent flags intentionally cannot be undone by toggling a switch.
