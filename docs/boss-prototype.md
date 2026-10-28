# Penjaga Resonans — three-phase combat prototype

Open `res://scenes/combat/boss-prototype-room.tscn` and run the current scene (F6), or launch:

```bash
godot --path . scenes/combat/boss-prototype-room.tscn
```

Click **Begin encounter**, or walk through the center trigger. Defeat the guardian, then retry in the same scene. Defeat also offers retry. **Return** uses an explicitly configured `return_scene`, otherwise a valid previous area from player data, with main menu fallback. The caller's prior position, loadout, health, mana, and movement/combat flags are retained for return. This is an offline standalone prototype; it does not provide multiplayer encounter replication or a campaign entrance/quest.

Branch: `feature/boss-prototype-combat-room`, created from current working commit `80b13ce` so the approved minimal incantation HUD and latest Quest/Enemy/Magis implementations are preserved. The user's pre-existing `project.godot` edit was left unchanged and uncommitted. The brief specifies Godot 4.6.x; this checkout declares 4.7 and the available verification engine was Godot 4.7.2 Flatpak. A separate 4.6 run is not claimed.

## Technical audit and implementation approach

Before shared changes, `tools/test-enemies.py` passed the existing Magis/Physics/UI and Enemy suites: 750 assertions, zero failures, plus import and arena startup checks.

The original Boss framework already supplied weighted resource-based attack selection, perception, health thresholds, shared spell casting, melee/AoE CombatRequest damage, and CombatLifecycle ownership. The base scene had no phases, an enemy-inappropriate default collision layer, and only a default placeholder sprite animation. It was retained as a reusable base, rather than turned into a specific encounter.

Issues addressed:

- Stun invalidated the attack but could leave ATTACK with no active attack or recovery timer. Interruption now clears warnings and casting, zeroes dash movement, enters a recoverable state, and preserves a minimum cooldown.
- Damage immediately restored `_can_attack`, potentially bypassing recovery. Damage can still interrupt, but cannot shorten the pending cooldown. Repeated hits do not continually restart the hurt-state timer or strand the state machine.
- Dash had no windup and only checked damage at its final position. It now locks a horizontal direction, warns, moves against terrain collision, and admits at most one successful contact strike per dash.
- AoE had only a console warning. Its native circle now uses the exact query radius; target results are deduplicated and filtered by combat layers/factions.
- Existing SceneTreeTimer defaults could let ranged/burst callbacks advance while paused. Attack waits and phase waits now pause with gameplay; active dash loops also suspend damage and elapsed time while paused.
- Phase changes, stopping an encounter, and death invalidate delayed callbacks using epochs. No health is restored between phases. The deepest eligible phase is selected when damage crosses multiple thresholds, and lethal damage goes directly to death.

The implementation extends this controller, configures one inherited guardian scene, and adds room/UI/presentation layers. SpellCastingComponent, CombatRequest, HitboxComponent, SpellExecutor, and CombatLifecycle remain the existing shared implementations. The RECOVERY state was appended, preserving the numeric values of the prior Boss states.

## Room structure and player setup

`scenes/combat/boss-prototype-room.tscn` contains:

- Flat 2400-world-pixel-wide combat space, a solid floor at y=480, and solid boundary walls on terrain layer 16.
- Named PlayerSpawn and BossSpawn markers, separate Actors ownership container, and a center Area2D start trigger.
- A fixed native ArenaCamera at (1200, 0), zoom 0.7. The inherited PlayerCamera's combat HUD and pause controls remain in use; its active camera is disabled so exploration/combat zoom tweens cannot crop the arena.
- A small start/result menu, default-controls reminder, and separately instanced boss health bar. No raised platforms, furniture, or environmental hazards.

The room initializes after deferred autoload campaign restoration, then snapshots caller state. The prototype player inherits the production player scene/script and changes only spell-access policy for its instance-local `training_spells` array. The temporary equipped set is Force, Strike, Resonate, and Shatterwave. These are **not added to permanent learned spells**. All requests still pass ordinary equipped checks, authority, SpellValidator, mana, cooldowns, preparation, and delivery.

The prototype actor has an explicitly empty quest owner, so practice casts/hits do not publish campaign quest progress or autosave receipts. No boss loot/quest/reward observer is attached. This avoids saving temporary training spells or farming XP/currency while leaving the shared Quest system intact.

Room defaults restore 400 HP and 400 MP, clamped to the caller's existing maxima. The prototype player instance regenerates 18 MP/s to support repeated chain practice; the production player's default regeneration and spell costs are unchanged. The original learned/equipped resources and caller health/mana are restored on exit.

Default controls: A/D movement, Space jump, Shift dodge, O casting stance, I/J/K/L directions, P clear. Aim with the mouse. Force is UP → DOWN. The existing Strike → Resonate → Shatterwave chain is DOWN → LEFT → DOWN → LEFT → DOWN. The footer lists these defaults; actual input actions still use the project's current keybindings.

## Guardian definition and phases

Configured scene: `components/NPCs/enemies/boss/resonance-guardian.tscn`, inherited from `boss.tscn`. It supplies 500 HP, all three phase resources, enemy collision layer 2, terrain mask 16, and 3000-pixel perception. Its body stops at walls, and player projectiles use the normal enemy collision mask.

Authored resources live under `data/npc/enemies/boss/resonance-guardian/`:

| Phase | Enters at | Chase speed | Attack pool | Presentation |
| --- | --- | ---: | --- | --- |
| 1 · Denyut | Initial / 100% | 130 | Melee Slam, Resonant Shot | Gold |
| 2 · Gema | ≤325 HP / 65% | 210 | Melee Slam, Resonance Dash, Twin Echo | Cyan |
| 3 · Resonans | ≤150 HP / 30% | 260 | AoE Shockwave, Resonant Burst, Melee Slam | Coral |

The same melee resource is reused. Ranged single/double/triple attack resources reference one `resonant-bolt.tres` SpellData. The shared base remains valid for other bosses with different resources.

The guardian hides the base placeholder sprite and attaches a native drawing-only presentation child. It provides a stone body/core, idle pulse, raised charging arms, hurt flash, and phase-change rings/colors. This is placeholder presentation, not finished character animation. The AI never depends on these drawings or on a looping animation finishing.

## Attack details

| Attack | Windup | Recovery/cooldown | Damage | Geometry / execution |
| --- | ---: | ---: | ---: | --- |
| Melee Slam | 0.70 s | 1.20 s | 24 | 240-pixel, 150-degree sector locked toward the target at windup |
| Resonant Shot | 0.75 s | 1.30 s | 18 / projectile | One shared Magis projectile |
| Twin Echo | 0.70 s | 1.40 s | 18 / projectile | Two shots, 0.18 s interval, 14-degree spread |
| Resonance Dash | 0.65 s | 1.50 s | 28 once | Horizontal direction locked at warning; speed = phase chase speed ×4 for 0.65 s |
| AoE Shockwave | 1.00 s | 1.60 s | 34 | 360-pixel circular physics query with 500 knockback |
| Resonant Burst | 0.65 s | 1.30 s | 18 / projectile | Three shots, 0.16 s interval, 24-degree spread |

`BossTelegraph` is a native Node2D sibling owned by the boss. It shows a melee sector, boundary-clipped dash corridor/arrow, projectile charge ring, or AoE circle with a filling inner ring. It reads the same BossAttackData values used by damage. Telegraphs are hidden immediately and freed on interruption, phase change, death, or encounter stop.

Melee tests target-center distance and the locked sector angle. AoE uses collider overlap with the drawn circle. Dash contact uses a radius of `melee_range × 1.5` around the moving boss; the warning is that circle swept along the projected, terrain-clipped center path. Real CharacterBody collision stops movement at the walls. One successful contact strike marks the dash as spent.

Ranged attacks duplicate the configured SpellData to remove duplicate preparation (BossAttackData owns the windup), then submit each shot through the existing casting component. Configured spread, intervals, authority, and per-shot casting validation remain in force. The prototype projectile has zero upfront mana/cooldown/recovery; its attack resource supplies the burst cooldown. This is an authored value, not a validation bypass. Shots travel at 650 pixels/s for up to 2400 pixels using the shared enemy projectile scene and damage delivery.

## Interruption and transition policy

Ordinary damage/stun cancels unresolved attack work and its warning, with recovery of at least `interruption_recovery` (default 0.65 s), the interrupted attack's configured cooldown, and any longer remaining cooldown. Completed in-flight projectiles are not retroactively undone by an ordinary hit or phase change. They remain owned and are cleaned up at death/encounter end/reset.

Phase transition cancels unresolved attacks/casting, stops old hurt/attack timers, changes resource, signals the HUD, and briefly protects the boss. All three authored phases configure a one-second transition and one-second protection. The active wait is the maximum configured transition/protection duration, then protection is released and a recovery gate precedes the next attack. New epoch checks stop superseded transition/attack callbacks from restarting behavior. Pausing suspends transition and attack waits.

The new generic phase fields are `transition_duration` and `phase_colour`. Generic attack resources add `melee_arc_degrees` (360 by default, preserving old circular melee) and `telegraph_colour`. Existing public boss/casting signals remain available.

## HUD and encounter lifecycle

`scenes/ui/boss/boss-health-bar.tscn` is reusable. `bind_boss()` subscribes to boss hurt, phase change, and death. It displays name, current/max health, a slim colored bar, phase name, and a brief transition announcement. It has no polling statistics panel or combat timers.

The room emits `initialized` and `encounter_state_changed` and owns this lifecycle:

`READY → INTRO → ACTIVE → VICTORY / DEFEAT → RESETTING → READY → INTRO → ACTIVE`

- READY: player can inspect the room; boss is inactive/protected. Button or center trigger starts INTRO.
- INTRO: briefly suspends player combat input, then activates combat mode and the boss.
- VICTORY: boss death is guarded once, owned projectiles/minions/warnings are cleaned, casting stops, and retry/return appears.
- DEFEAT: the room handles death, stops boss attacks and player casting, cleans owned attacks, and presents retry/return. It disables only this prototype player's campaign PlayerDeath routing so defeat does not jump to the main menu.
- RESETTING: invalidates room callbacks, frees the old Actors children, waits for deletion, then creates fresh player, boss, and HUD. Health/mana, boss HP/phase/cooldowns, spawn positions, and input are restored before the next intro. Button spam cannot create overlapping resets.

Exit restores the caller snapshot, unregisters the prototype player, and leaves existing progression/settings untouched. If a previously registered player remains valid, its manager reference is restored. The existing pause menu continues to work during active combat. An actual multiplayer peer is rejected; Godot's normal OfflineMultiplayerPeer is supported.

## Verification

The pre-change shared baseline passed. Final results are recorded from actual runs, counting each assertion suite once:

| Suite | Source checks | Failures |
| --- | ---: | ---: |
| Spell regression | 71 | 0 |
| Incantation assistant | 60 | 0 |
| Player combo chains | 23 | 0 |
| Spell equipment UI | 38 | 0 |
| My Spells | 148 | 0 |
| Physics curriculum | 272 | 0 |
| Enemy pipeline | 138 | 0 |
| Boss prototype | 70 | 0 |
| **Total** | **820** | **0** |

Editor import and the existing Physics laboratory/Enemy arena startup checks also passed. The dedicated boss suite additionally runs from a fresh Web-preset PCK outside the source project; **70 packed checks, zero failures**. The source and packed assertion total is **890**, excluding startup/export checks.

The boss suite covers safe floor placement, resources, player acquisition, actual production Magis damage against the enemy layer, all attack types/counts, warning-before-damage, successful AoE escape, real dash-wall collision, single dash damage, cooldown preservation under repeated hits, stun recovery, pause/resume, both thresholds, multi-threshold damage, protection expiry, no health refill, once-only death, stale callback cleanup, victory, defeat, retry from both outcomes, state restoration, and no permanent training spell/quest/XP/currency grants.

Reproduce:

```bash
GODOT=godot
python tools/test-enemies.py --godot "$GODOT"
"$GODOT" --headless --path "$PWD" tests/boss-prototype.tscn -- --quest-test-mode
"$GODOT" --path "$PWD" --resolution 1280x720 scenes/combat/boss-prototype-room.tscn -- --quest-test-mode --capture-boss-prototype
```

For Flatpak, use a wrapper as `--godot` (for example `/tmp/godot-assistant` in this verification environment), isolate XDG_DATA_HOME, and place exports in a host/Flatpak-shared directory. Tests use `--quest-test-mode` to avoid campaign save loading/writing. For packed verification, export with `--headless --editor --export-pack Web /absolute/shared/path/boss-prototype.pck`, then run from outside the source project with `--headless --path /absolute/shared/path --main-pack /absolute/shared/path/boss-prototype.pck res://tests/boss-prototype.tscn -- --quest-test-mode`.

Eleven actual renderer captures were inspected after 1280×720 and 1920×1080 launches; the project stretches its 1920×1080 viewport, so saved images are 1920×1080. These are scripted production-room fixtures, including deliberate actor placement/health changes for phase/warning screenshots. They verify visibility/layout and real callback execution, not human reaction-time balance or an unassisted full-fight win. The headless suite separately verifies real player spell damage and full victory/defeat/retry lifecycle.

Screenshots: [ready](previews/boss-prototype/01-ready.png), [melee](previews/boss-prototype/02-melee-windup.png), [phase two](previews/boss-prototype/03-phase-two-transition.png), [dash](previews/boss-prototype/04-dash-windup.png), [projectiles](previews/boss-prototype/05-ranged-burst.png), [phase three](previews/boss-prototype/06-phase-three-transition.png), [AoE warning](previews/boss-prototype/07-shockwave-warning.png), [victory](previews/boss-prototype/08-victory.png), [retry](previews/boss-prototype/09-retry.png), [defeat](previews/boss-prototype/10-defeat.png), [retry after defeat](previews/boss-prototype/11-retry-after-defeat.png).

Known limitations: native placeholder art/poses, provisional balance, no manually completed unassisted fight, no live multiplayer or browser/WebAssembly test, and no separate Godot 4.6 engine verification. The existing project UID/world-ID warnings and shutdown ObjectDB/resource-in-use diagnostics remain; the runners distinguish those known shutdown diagnostics from script/runtime errors. No campaign portal, rewards, or boss music is added. The footer describes default bindings, while gameplay respects configured bindings.

## Author another boss

1. Inherit the existing Boss scene; assign an enemy collision layer/mask, appropriate body shape, name, HP, and detection range.
2. Author BossAttackData resources and valid ranged SpellData references. Author ordered BossPhaseData resources starting at 1.0 and descending health thresholds. Reuse attack resources between phases.
3. Assign the phases to the inherited scene. Set transition duration/protection, colors, move speeds, cooldowns, and geometry deliberately. Keep warnings and actual ranges in the same resource.
4. Supply final animation frames or a presentation-only child; AI timing does not need to wait for looping sprite animations.
5. Instance BossHealthBar and bind the boss. Use `set_combat_enabled()` for room ownership, and clean owned actors on exit/reset.
6. Reuse/adapt this room controller and its temporary training player only for practice rooms; normal campaign players keep learned-and-equipped authorization. Add boss-specific regression and rendered cases before tuning balance.
