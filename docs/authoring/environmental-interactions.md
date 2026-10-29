# Environmental interactions

Environmental Interactions V1 provides reusable kampung utility props and school practical equipment. Run [the standalone lab](../../scenes/environment-testing/environment-interactions-lab.tscn) with F6. Its twelve station buttons move the real player between demonstrations; **Reset station** and **Reset room** restore the connected mechanisms. It grants a temporary training loadout and restores the previous loadout when leaving. Campaign saving is rejected by SaveManager because the lab is not a registered ZoneRoot.

## Author a prop

Drag a scene from `res://components/environment/` into a level. Make its `data` Resource unique before changing a shared example. The common root is [EnvironmentDevice](../../components/environment/core/environment-device.gd), with validated [EnvironmentDeviceData](../../data/environment/environment-device-data.gd). Physics, interaction, receiver and art nodes are owned by the component; keep the authored root's name and path stable when enabling persistence.

The root exports `links`, `input_sources`, `source_tank`, `destination_tank`, `valves`, `light_targets`, `water_volume`, `blocking_debris` and optional `timeline`. All NodePaths are relative to that root. For example, a switch and gate sharing a parent use `../Gate`, not a path from the scene root. The authored [lab layout](../../scenes/environment-testing/environment-lab-layout.tscn) contains working Inspector examples.

An [EnvironmentLink](../../data/environment/environment-link.gd) addresses the target root, then resolves its typed `Actuator` child. Choose a port by its enum name:

| Port | Meaning |
| --- | --- |
| POWER | Supply availability; keeps the device's requested switch position |
| ENABLE | Requested on/off position |
| INPUT | One input value, keyed by the sending root; list sources on the receiving relay |
| UNLOCK | Lock permission independently of power and position |

`inverted` makes a normally closed connection or emergency cutoff. Effective output is enabled AND powered AND unlocked AND the configured input logic. `NONE` ignores inputs; `AND` requires every authored source; `OR` accepts any authored source. Missing sources evaluate false. Output changes emit `activated(bool)` on the root and `changed(bool)` on the actuator. Initial output propagates after all siblings are ready. A visited-actuator/port pulse and a 256-step limit terminate cycles; do not use feedback circuits as clocks or expect arbitrary Boolean loops to converge to a globally unique solution.

## Component recipes

| Mechanic | Scene / typical Inspector settings | Connections and verification |
| --- | --- | --- |
| 01 Light switch + fuse | `light-switch.tscn`, `fuse-box.tscn`, `lamp.tscn`; switch `initial_enabled=false`, `initial_power=false`; lamp `initial_enabled=true` | Fuse → switch POWER; switch → lamp POWER. F toggles each. Lamp owns a real PointLight2D; optional `light_targets` accepts other Light2D nodes. |
| 02 Gates and locks | `powered-gate.tscn`, `keyed-door.tscn`; `size=(36,240)`, `key_id`, `consume_key`; `auto_close=3` for a timed door; `manual_interaction=false` for externally controlled gates | Link to ENABLE or POWER as appropriate. Output opens collision. Powered gates disable manual interaction, so F cannot bypass their circuit. Enable manual interaction for a normal hand-operated gate. Empty key means unlocked; keys reuse Player_Global_Data's existing key list. Lab key pedestal uses F. |
| 03 Tap / valve | `water-tap.tscn`, `water-valve.tscn`; `valve_opening=0.5` for half flow; `flow_rate=15` L/s | Tap can transfer between assigned source/destination tanks. `valves` requires every listed valve to be open and multiplies by the smallest opening. F closes flow. |
| 04 Pump / tanks | `water-pump.tscn`, `water-tank.tscn`; source `initial_volume=100`, destination `0`, `capacity=100` | Set pump source/destination, optional valves, and supply POWER. Transfer clamps to source volume and destination room. `volume_changed`, `full`, `empty` are real volume signals. |
| 05 Ceiling fan | `ceiling-fan.tscn`; `fan_speed=6`, `fan_acceleration=6`; optional `airflow_enabled`, `airflow`, `airflow_max_mass=15` | Switch → POWER. Rotor accelerates/decelerates. Airflow applies force only to light RigidBody2D objects; player airflow requires explicit `player_airflow`. |
| 06 Drain | `drainage-channel.tscn`; source/destination tank paths and `blocking_debris` | Drain has its own conserved volume. Blocked inlet fills that compartment; a full blocked channel emits `overflow` once per episode and backpressures the source. No water is fabricated or silently discarded. Moving/breaking debris restores outlet flow. |
| 07 Pressure plate | `pressure-switch.tscn`; `minimum_weight=40`, `activation_delay=0.15`, `deactivation_delay=0.15` | Plate → gate ENABLE. Mass is deduplicated by body instance; rigid bodies use actual kg, player uses `player_weight`. Choose HOLD, TOGGLE, ONE_SHOT or TIMED; configure `activation_seconds` for TIMED. |
| 08 Magis receiver | `magis-receiver.tscn`; assign [cooled rule](../../data/environment/cooled-rule.tres) | R explicitly selects neutral devices, O + equipped incantation casts. Actual cooled status activates this example; no spell-name comparisons. Q still cycles hostiles. |
| 09 Training turret | `training-turret.tscn`; `initial_power=false`, `warning_seconds=0.7`, `firing_interval=2`, `attack_range=800`, `max_health=80` | Start switch → POWER; emergency switch → inverted ENABLE. Existing SpellData/projectile/executor deals damage. `outgoing_damage` is a multiplier on the spell payload. Nonlethal requires direct damage/impulse effects; damage stops at 1 HP. |
| 10 Breakables | `magis-breakable.tscn`, `floating-crate.tscn`; `max_health=25`, optional `loot`, `persistent` or `respawn_seconds` | Existing Hitbox damage, impulses, LootData and WorldPersistence are reused. Broken collision is disabled. Legacy destructible boxes also accept neutral environmental Magis. Structural/magnetic capabilities opt into existing effects. |
| 11 Relay | `electrical-relay.tscn`; `initial_enabled=true`, `logic=AND` or OR; list `input_sources` | Each receiver sends INPUT; relay → gate ENABLE/POWER. Cut any required input and the gate closes. Inverted connections supply normally closed behavior. |
| 12 Moving platform | `moving-platform.tscn`; [MovingPlatformData](../../data/environment/moving-platform-data.gd), `speed=120`, `wait_seconds=0.5`, route PING_PONG | ENABLE/POWER starts/stops the actual AnimatableBody2D. `waypoints` are relative offsets; `waypoint_nodes` can reference markers. Power loss holds position and resumes the route. `reverse()` reverses travel. Static terrain stops motion; author rider clearance. |

## Rules and Magis

[InteractionRule](../../data/environment/interaction-rule.gd) selects INTERACT, ENTER, EXIT, CONTACT, PRESSURE, SPELL, DAMAGE, STATUS, IMPULSE, PROJECTILE or SIGNAL. The receiver consumes actual body events and successful SpellExecutor effects. For SIGNAL, call the typed `receiver.receive_event(InteractionRule.Event.SIGNAL)` from an authored signal connection. Actuator links independently consume Boolean output and do not count as spell hits.

`effect_kind`, `required_status`, `required_capability`, `minimum_magnitude`, `required_hits` and `required_charge` narrow eligibility. Charge is the qualifying cast's authored upfront plus channel mana cost, not an invented spell school/name score. A cast counts once even if it carries damage, slow and cooled effects. The bounded cast cache prevents multi-effect duplicate counts; `reset_after_activation` permits subsequent casts to activate again. Examples include [three hits](../../data/environment/three-hit-rule.tres), [charge](../../data/environment/charge-rule.tres) and [impulse](../../data/environment/impulse-rule.tres).

Capabilities normalize hyphens to underscores in metadata. Structural/magnetic are backed by existing effects; capabilities alone do not manufacture a new simulation. A configured rule does not make a prop a hostile actor, grant XP or publish enemy-defeat quest events. [EnvironmentalTarget](../../components/environment/core/environmental-target.gd) permits explicit neutral interaction through projectiles, direct targets, areas and beams. Turrets remain genuine hostiles. R never replaces Q's hostile cycle; Q clears explicit device mode.

## Collision and input

Terrain/props use layer 16; players layer 1; enemy layer 2. Receiver, gate, tank, turret and breakable bodies have real rectangular collision. Controls configured with a Magis rule also keep a hit collider enabled. Other controls are nonblocking; their interaction/pressure/airflow sensors are separate. Crates use RigidBody2D and mask 17; platforms use AnimatableBody2D. Keep the receiver's collider enabled so physical projectiles can hit it.

Default controls are **F interact, E push, Q next hostile, R next device, B phone, O casting stance, I/J/K/L incantations**. All corresponding actions are remappable in Settings. This resolves the baseline's conflicting E interaction/push and F phone mappings. DetectionComponent now routes props, NPCs, old doors, keys and elevators through one nearest eligible target, with stable path ties and event consumption. Existing dialogue/phone interception wins before world interaction. Space/WASD traversal remains unchanged.

## Water and persistence

[WaterVolume2D](../../components/environment/water/water-volume.gd) exports region, fill, buoyancy, drag, current, player swimming/speed, optional splash and surface texture. Tank `water_volume` sets the surface from volume/capacity. This is a rectangular displaced-body approximation, not a fluid solver. Force uses actual mass and immersed fraction. Player movement is an isolated [water helper](../../components/environment/water/player-water-movement.gd); leaving or freeing the volume removes membership and leaves ordinary movement available.

Persistent mechanisms use existing WorldPersistence `activated`/`broken` Boolean flags under an authored ZoneRoot. `persistent=true` latches an activated story mechanism; use transient switches for everyday on/off controls. Stable scene path + relative node path defines identity. Do not rename persistent roots after shipping without a migration plan. Destruction restores with collision removed. Timers, volumes, fan speed, turret phases, pressure occupancy, platform position and active statuses are transient and reset on reload. No new save schema or parallel save file exists. Configured timelines never begin during SaveManager restoration.

## Validation

Run [core tests](../../tests/environment-interactions.tscn), [live lab tests](../../tests/environment-lab-gameplay.tscn) and [fresh-process persistence tests](../../tests/environment-persistence.tscn). See [testing commands and evidence](../reference/testing-and-validation.md) and [the visual workflow](environmental-visuals-and-animations.md). Confirm actual collision, input, spell impact, reset and exported-PCK behavior before moving a puzzle into the campaign.
