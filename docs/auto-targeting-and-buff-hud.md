# Automatic targeting and larger buff icons

Player casting uses automatic enemy locking instead of mouse aiming. The [PlayerTargetLock component](../components/characters/player/player-target-lock.gd) selects the nearest living, visible hostile within 1200 world units and with an unobstructed terrain-layer-16 line of sight. Allies, neutral actors, hidden/dead actors and targets outside that range are excluded. The training dummy participates as a normal enemy target.

The chosen lock remains stable when another enemy becomes closer. **Q** advances through the eligible enemies sorted by distance from the player and wraps to the nearest after the last candidate. Death, deletion, hiding or loss of hostility replaces the target immediately. Range and terrain obstruction use a 150 ms loss grace period before reacquiring, preventing boundary flicker. Valid visibility resets that timer; repeated input/aim refreshes do not advance it. Equal-distance candidates have a stable path-based tie break. A gold bracket and `LOCK · Q Next` label mark the selection; the hint uses the actual key binding. The [visual marker](../components/characters/player/player-target-reticle.gd) is a child of the selected enemy, using local collision bounds and inheriting its native 2D interpolation. It never mixes raw world positions with the player’s interpolated transform. Q reparents the marker and resets its interpolation; freeing the player cleans it up. Rendering performs no line-of-sight queries. See [Godot’s 2D interpolation model](https://docs.godotengine.org/en/latest/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.html).

Q is the separate `cycle_target` action, exposed as Next Enemy Target in Settings. It does not stop movement, clear an incantation, cancel a cast or consume mana. Key-repeat events do not skip targets. Phone, dialogue, quest-offer and paused states intercept switching. Combat exit clears the lock. The former `casting_aim_lock` action is retained as optional Stop Movement, starts unbound and has no effect on aim. Mouse motion has no effect on spell direction or player movement; movement is stepped only by physics.

[Player input and aiming](../components/characters/player/player.gd) points the casting marker toward the selected enemy's body center. With no eligible target, movement provides directional aiming and otherwise the previous direction is retained. Each offensive queued request records the enemy selected when its incantation completes. Preparation tracks that enemy's movement through dispatch; changing the current lock does not redirect previously queued spells to a different enemy. Direct-target spells use the recorded target, with their existing target-range validation. Beams track the recorded enemy while active. Projectile speed/range, area placement distance, spell-specific range limits, mana costs, channeling and individual reuse cooldowns remain authored SpellData settings. Released projectiles remain ordinary physics projectiles.

## Buff HUD

[StatusEffectsHUD](../scenes/ui/status-effects/status-effects-hud.gd) places active buff/debuff icons to the right of the health/mana panel. [StatusEffectIcon](../scenes/ui/status-effects/status-effect-icon.gd) now uses **52×52** panels instead of 34×34; glyphs, stack counts and duration indicators scale with the panel. Eight nodes remain cached. A grid uses 8-pixel gaps and wraps as space narrows. The visible icon budget reserves space for `+N` when needed, so the overflow label stays inside the viewport. If the viewport cannot fit a single icon beside the panel, effects fall below the stats panel.

The stats and dash panels use fixed top-left offsets so they remain readable at smaller native viewport sizes. The boss header avoids the stats/effect region. Push's cooldown stays at the bottom-left. Effect timing, classification, grouping, prioritization, tooltips and modal/death visibility rules are unchanged.

## Verification

Run the focused suite:

```bash
flatpak run org.godotengine.Godot --headless --path . tests/target-lock-and-hud.tscn -- --quest-test-mode
```

The focused suite passes 37 checks. It checks automatic nearest acquisition, physical Q cycling/wrapping, key repeat, stable selection, mouse independence, movement and incantation preservation, death/range/hidden/freed/terrain cases, direct casting, aim updates during preparation, phone interception, combat exit, and 52-pixel HUD placement/wrapping/overflow at 800×600, 1280×720 and 1920×1080.

The existing [42-spell live physics audit](spell-runtime-repair.md) continues to exercise real delivery and effects. Its mouse test now verifies that mouse motion leaves aim unchanged. [Initial lock](previews/snappy-combat/pushback-1280.png) and [after physical Q](previews/snappy-combat/target-lock-next-1280.png) are actual renderer captures; both are also captured at 1920×1080. Multiplayer and human combat balance have not been playtested.

## Jitter regression (2026-10-29)

`tests/target-lock-stability.tscn` passes 13 headless checks and 14 checks with an actual rendering display. Cases cover temporary range/LOS flicker, repeated refresh calls, sustained target loss, dead targets, immediate Q selection, and strict rejection of direct casts against obstructed retained targets without mana payment.

The rendering fixture runs physics at 10 Hz while moving the player, a scaled enemy and the camera. Six rendered frames measure the gold marker against a cyan body outline, confirming stable pixel alignment between physics ticks. The existing target/HUD suite passes all 37 checks; the live 42-spell physics audit passes all 46 checks. These are automated source/render checks, not multiplayer or human playtesting.

```bash
flatpak run org.godotengine.Godot --headless --path . tests/target-lock-stability.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --path . tests/target-lock-stability.tscn -- --quest-test-mode
```
