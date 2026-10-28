# Incantation Chain Assistant V1

> Historical implementation/verification record. The body below preserves earlier design descriptions, commands and measurements; it is not a newly executed test or the current authoring contract. Use [the current guide](authoring/spells.md) and [Godot 4.7 workflow](developer-workflow.md). Current Player default is CHAINED with independent shared-prefix execution; the assistant now shows only valid next-direction icons. Save V1 supersedes earlier quest-only persistence limits.

Implemented on `feature/incantation-chain-assistant`, based on reviewed Quest/Enemy/Magis V2 commit `4423abf`. The working tree was clean before work began; no repository AGENTS.md was present. No spell resource, ID, UID, incantation, authored effect, or stat was changed. The base project declares Godot 4.7; verification used the installed Godot 4.7.2 Flatpak. Godot 4.6 compatibility was not separately verified.

## Preserved gameplay

The assistant observes the existing equipped-spell resolver and casting component. It never supplies inputs, executes spells, pays mana, applies effects, or authorizes a cast.

The actual authored Physics chain is:

| Entered directions | Recognition | Upfront cost | Remaining continuation |
| --- | --- | --- | --- |
| DOWN → LEFT → DOWN | Strike | 15 MP | LEFT |
| DOWN → LEFT → DOWN → LEFT | Resonate | 25 MP | DOWN |
| DOWN → LEFT → DOWN → LEFT → DOWN | Shatterwave | 22 MP | Terminal: resolver clears |

Strike triggers immediately at its exact prefix. Its sequence remains available for Resonate, which triggers independently; Shatterwave also triggers independently. The total upfront cost when all three start is 62 MP. Mana regeneration can change the visible balance during the demonstration. Preparation/recovery can queue later requests; queue acceptance does not imply successful execution or payment.

`CHAINED` still continues the current trie branch first. At a completed prefix, a direction with no continuation may start another root incantation when the existing strategy permits it. Guided mode separates **CONTINUE** from **NEW CHAIN** so accepted restart inputs are not mistaken for extensions. IMMEDIATE, CONFIRMATION, and DELAYED retain their original matching behavior. Terminal sequences still clear immediately under the existing resolver policy; recognition/lifecycle events preserve the terminal result afterward.

## Resolver queries

`components/spells/incantation-resolver.gd` adds these read-only APIs:

| API | Result |
| --- | --- |
| `get_sequence_snapshot()` | Independent typed array of entered directions |
| `get_valid_next_keys()` | All currently accepted directional inputs, including allowed restarts |
| `get_continuation_keys()` | Directions in the current trie node |
| `get_restart_keys()` | Accepted root starts that do not continue the current node |
| `starts_new_sequence(key)` | Whether the accepted input begins an independent incantation |
| `get_current_exact_match()` | Current node's exact spell, including a completed prefix with extensions |
| `get_matching_spells()` | Current exact match and descendant spells |
| `get_reachable_chain_spells()` | Descendants excluding the already reached exact match |

An empty sequence exposes equipped root starts and all reachable equipped spells. Candidates sort by total incantation length (equivalent to remaining length for a shared current prefix), name, then spell ID. Key order is UP, DOWN, LEFT, RIGHT. Returned arrays can be changed without altering the trie; SpellData references remain the real authored resources and should be treated as read-only by consumers. Queries do not change pending recognition, elapsed time, queue state, or mana. Authored prefix depth is not capped by the assistant.

`changed` notifies observers of input changes, clears, and equipment rebuilds. Shared prefixes remain intentional chain relationships. Resolver `validation_errors` explicitly records exact equipped-incantation collisions; sorted spell IDs select the same representative regardless of equipment array order. The library continues diagnosing catalogue duplicates separately. Content authors should resolve exact collisions, rather than depend on the representative selection.

## Request lifecycle

The existing `state_changed`, `cast_failed`, `cast_completed`, boolean `request_cast()` and boolean `enqueue_cast()` interfaces remain supported. Both request methods accept an optional trailing `chain_id`, defaulting to zero for older callers.

New signal:

API signature (not a standalone executable script):

```text
request_status(request_id, chain_id, spell, status, reason)
```

Request IDs increase within each casting component and remain unchanged when a request is dequeued. They are separate from the existing `SpellCastContext.cast_id`. Context now also carries `request_id` and `incantation_chain_id`.

| Status | Meaning |
| --- | --- |
| RECOGNIZED | A spell request was submitted; this does not authorize it |
| QUEUED | The bounded queue actually accepted the request |
| PREPARING | Validation passed and the existing upfront payment succeeded |
| CHANNELING | The existing channel lifecycle began |
| EXECUTING | Delivery is being attempted; it may still fail |
| COMPLETED | Delivery succeeded and the existing completion path ran |
| FAILED | Start/admission validation rejected this request, with its actual reason |
| INTERRUPTED | Active preparation/channel/delivery was interrupted, with its actual reason |
| CANCELLED | Explicit cancellation or removal of a queued request |

A request started immediately skips QUEUED. A queued request is revalidated through the same start path when dequeued. Later enqueues cannot jump ahead of an existing queue during an idle frame. Saturation reports a distinct failed request. Cancellation reports every affected queued request as well as the active request, and component exit performs cancellation cleanup. Delivery failures and lost prepared targets follow the existing interruption path, retaining their specific reason.

The casting lifecycle still reports successful completion separately from recognition, queue acceptance, and preparation. The core player feedback label retains these results. Live channel payment, refunds, and authoritative execution are unchanged.

Each player assigns an independent chain identity at a new input sequence or permitted restart. Queued requests keep that identity after clear, equipment rebuild, or terminal reset. The optional assistant no longer displays a chain counter or stores completed spell icons.

## Minimalist HUD

The reusable native Control scene is `scenes/ui/spell-combat-ui/incantation-assistant.tscn`. Following visual review, the large panel and its title, sequence, spell predictions, cost/readiness labels, result cards, and chain display were removed. Guided mode now shows **only valid next-direction icons**, enlarged from 26 to 64 viewport pixels in a transparent lower-center row. All eligible next inputs come from `get_valid_next_keys()`, including permitted restarts. There is no panel, background, border, text, or dynamically calculated panel height.

The local production Player owns the assistant on a CanvasLayer after the remote-player early return. Four cached TextureRects are toggled by resolver signals; there is no forecast timer or recurring layout rebuild. The row ignores mouse input and hides outside casting stance, during dialogue/pause/death, and in Minimal/Off modes. Core combat feedback and the existing repertoire remain available separately. The casting system, prediction query APIs, mana validation, and request lifecycle are unchanged by the visual simplification.

## Clear, cancellation, settings, and authority

P's existing `clear_incantation` action now clears only directional input. Accepted preparation/queues continue. `Player.cancel_active_casting()` cancels eligible casting and queued execution through the existing component. The new `cancel_casting` action is initially unbound and appears as **Cancel Active Cast / Queue** in existing keybinding settings; bind it to cancel channelled spells explicitly. It works outside casting stance as well. Damage, stun/silence, death, authority checks, and existing interruptions remain in force.

The settings menu adds Guided / Minimal / Off, with Guided as the new-player default. Save persists to `user://incantation-assistant.cfg`; Cancel leaves the assistance preference unchanged, and Reset selects Guided. Boot restores the preference and existing keybindings. Keybind persistence now preserves both logical and physical keycodes, while loading older integer entries. This prevents saving the new presentation setting from erasing the project's physical I/J/K/L bindings. Optional file-path arguments permit isolated persistence tests.

Dialogue and pause hide/suspend the assistant. Exit stance and death hide it; tree ownership and signal connections clean it up with the player on transitions. Remote avatars never create a local assistant. Gameplay still requires the existing SpellExecutor authority checks. Client prediction is advisory, and this work does not implement multiplayer cast requests or replication.

To make a new spell discoverable: author/validate SpellData, register it in the existing library/export manifest, learn it, and equip it through the existing equipment pipeline. The equipment signal rebuilds the trie and clears stale input displays while accepted requests retain their original association. No assistant-specific spell list is maintained.

## Minimalist revision verification

After removing the panel, the updated assistant suite passed **60 checks, zero failures**, and all ten real-renderer previews were regenerated and inspected. The larger next-key-only row was verified at a 1280×720 window with the project's 1920×1080 stretched viewport. The broad source/PCK counts below describe the earlier V1 delivery; those broad suites were not rerun for this presentation-only revision.

## Original V1 verification — 27 October 2026

Most recent successful run per suite, counted once (repeated development runs excluded):

| Suite | Source checks | Packed checks | Failures |
| --- | ---: | ---: | ---: |
| Spell regression | 71 | — | 0 |
| Incantation assistant | 60 | 60 | 0 |
| Production player combo chains | 23 | 23 | 0 |
| Spell equipment UI | 38 | — | 0 |
| My Spells | 148 | — | 0 |
| Physics curriculum | 272 | — | 0 |
| Enemy pipeline | 138 | — | 0 |
| Quest pipeline, including inventory/rewards | 172 | 172 | 0 |
| Quest persistence writer / reader | 4 / 7 | 4 / 7 | 0 |
| Quest accessibility | 90 | 90 | 0 |
| NPC world boot rooms 1 / 2 / 3 | 4 / 4 / 4 | 4 / 4 / 4 | 0 |
| **Total** | **1035** | **368** | **0** |

Additionally: editor import, main-menu startup, Physics lab, Enemy arena, Quest arena, and Web-preset PCK export completed. These startup/export checks are not added to assertion counts. No standalone inventory regression suite exists; quest integration covers inventory allocation, consumption, and reward behavior.

The dedicated assistant suite covers trie branches/restarts, nonmutating queries, a 32-direction authored spell, exact duplicate diagnostics, queue status/payment/correlation, later mana/cooldown failures, saturation, silence/stun, channel payment/cancellation, clear vs cancel, independent chains, mode/visibility changes, dialogue/pause/death, rapid input, real resource icons/costs, settings reload, and physical keybinding persistence. Existing spell regression covers the other resolver strategies and effect/authority boundaries.

Rendered verification uses the actual production Player/HUD and authored Strike/Resonate/Shatterwave resources in the Physics lab. It sends directions to the normal player resolver path, rather than synthesizing success events. Captures were inspected after launches at 1280×720 and 1920×1080; the project stretches its 1920×1080 viewport, so saved viewport PNGs are 1920×1080 in both cases. The compact layout leaves the lab character and targets visible.

Screenshots: [empty stance](previews/incantation-assistant/01-empty.png), [partial input](previews/incantation-assistant/02-prefix.png), [Strike](previews/incantation-assistant/03-strike.png), [Resonate](previews/incantation-assistant/04-resonate.png), [three completed spells](previews/incantation-assistant/05-chain-complete.png), [mana failure](previews/incantation-assistant/06-mana-failure.png), [invalid input](previews/incantation-assistant/07-invalid.png), [Minimal](previews/incantation-assistant/08-minimal.png), [Off](previews/incantation-assistant/09-off.png), [outside stance](previews/incantation-assistant/10-outside-stance.png).

Reproduce with a native Godot executable:

```bash
GODOT=godot
python tools/test-physics.py --godot "$GODOT"
python tools/test-enemies.py --godot "$GODOT"
python tools/test-quests.py --godot "$GODOT" --skip-shared --packed
"$GODOT" --headless --path "$PWD" tests/incantation-assistant.tscn -- --quest-test-mode
"$GODOT" --path "$PWD" --resolution 1280x720 scenes/spell-testing/incantation-chain-preview.tscn -- --quest-test-mode
```

For a packed assistant check, export a fresh pack with `--headless --editor --export-pack Web /absolute/shared/path/assistant.pck`, then run the engine outside the source project with `--headless --path /absolute/shared/path --main-pack /absolute/shared/path/assistant.pck res://tests/incantation-assistant.tscn -- --quest-test-mode`. For Flatpak, use a wrapper executable for `--godot`, an isolated XDG_DATA_HOME, and a host/Flatpak-shared TMPDIR for packed runner output. The project-provided `--quest-test-mode` prevents loading or saving campaign progress during tests. Production preference files are not overwritten by the dedicated persistence checks.

Limits: existing project ObjectDB/resource-in-use shutdown diagnostics and the uppercase world-ID warning remain; runners distinguish these from script/runtime failures. Verification is on Godot 4.7.2, not a separate 4.6 engine or browser/WebAssembly build. No live multi-peer session, full campaign playthrough, controller usability session, or exhaustive HUD assessment in every world was performed. The captures demonstrate the real lab experience, not all possible camera/target layouts.

## Changed-file map

- Resolver: `components/spells/incantation-resolver.gd`.
- Lifecycle/context: `components/spells/spell-casting-component.gd`, `spell-cast-context.gd`.
- Player integration: `components/characters/player/player.gd`.
- Preferences/input: `autoloads/player-data.gd`, `project.godot`, `scenes/ui/menus/settings_menu.gd`.
- HUD: assistant, repertoire, and spell-slot scripts/scenes under `scenes/ui/spell-combat-ui/`.
- Verification: `tests/incantation-assistant.gd/.tscn`, updated `tests/player-combo-chains.gd`, `tools/test-physics.py`, rendered preview script/scene under `scenes/spell-testing/`, and the lab's corrected clear/cancel help text. New scripts include engine-generated UID files.
- Documentation: this document, Magis pipeline/report updates, and ten actual renderer PNGs under `docs/previews/incantation-assistant/`.

## Combat feedback V1

The assistant still renders only valid next-direction icons. The separate [status HUD](status-effects-hud.md) anchors bottom-left, while [accepted-input particles](incantation-input-feedback.md) originate on the player. Neither changes trie prediction, incantations or independent shared-prefix execution. Assistant mode and keybindings remain separate from character saves.
