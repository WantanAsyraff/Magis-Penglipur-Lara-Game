# Bakau integration and regression evidence

Validated with Godot **4.6.1 stable** on Linux on the current working tree, including preserved pre-existing edits. Those edits are excluded from quest commits; this does not claim an independently tested clean checkout. All automated gameplay launches pass `--quest-test-mode`; test save files are isolated from `user://quest-progress-v2.json` and cleaned by the reader/suite.

## Commands and measured results

```sh
python3 tools/test-enemies.py --godot /tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64
python3 tools/test-quests.py --godot /tmp/magis-godot/Godot_v4.6.1-stable_linux.x86_64 --skip-shared --packed
```

Omit `--skip-shared` for a single command that includes existing Magis/Enemy checks. `--packed` exports the existing Web preset to an isolated temporary PCK and runs tests from `/tmp`, outside the source project. This verifies pack resource/runtime resolution, not a browser deployment.

| Suite | Checks | Failures |
| --- | --- | --- |
| SPELL_REGRESSION | 71 | 0 |
| SPELL_EQUIPMENT_UI | 38 | 0 |
| MY_SPELLS | 148 | 0 |
| PHYSICS_CURRICULUM | 272 | 0 |
| ENEMY_PIPELINE | 138 | 0 |
| QUEST_PIPELINE | 172 | 0 |
| QUEST_PERSISTENCE writer | 4 | 0 |
| QUEST_PERSISTENCE fresh reader | 7 | 0 |
| QUEST_ACCESSIBILITY | 90 | 0 |
| NPC_WORLD_BOOT, three fresh main scenes | 12 | 0 |
| Packed QUEST_PIPELINE repeat | 172 | 0 |
| Packed persistence writer / fresh reader repeat | 4 / 7 | 0 / 0 |
| Packed QUEST_ACCESSIBILITY repeat | 90 | 0 |
| Packed NPC_WORLD_BOOT, three scenes | 12 | 0 |

Source assertions total **952**; packed repetitions add **285** executed assertions. Editor import, resource-reference scan, Physics laboratory startup, Enemy arena startup, Bakau arena startup and PCK export also pass (exit 0, no script/runtime errors). Existing dummy/boss and spell behavior is covered by the unchanged shared suites.

The project still emits its pre-existing ObjectDB leak warning and **25 resources still in use at exit**. Existing asset UID warnings fall back to text paths. Runners retain full logs and reject SCRIPT ERROR or other ERROR output; they explicitly report the known shutdown resource diagnostic. These diagnostics are not claimed fixed by this task.

## What the quest suite actually exercises

- All fourteen definitions register; ten exact Bakau IDs/prerequisites/objective quantities/XP/item rewards and four original FLAC identities are asserted.
- Every Bakau quest uses the production QuestBoard/QuestCatalogue view-offer and hand-in callbacks plus explicit QuestOfferDialog decisions, real Enemy V2 hitbox deaths for kills, and real production DroppedItem pickup for acquisition. Each reaches readiness, grants exact rewards and rejects a second hand-in. This is not a `.tres`-load-only check.
- All four FLAC quests use QuestNPCComponent offer/complete callbacks, original target IDs and actual enemy/inventory events. XP/currency are checked and repeated legacy callbacks cannot duplicate them.
- Mixed fish 2 meat + 1 bone + 2 scales counts as five; separate tissues/kills remain independent. Concurrent quests, exact-ID rejection, duplicate death/receipt protection, optional/ordered/ANY objectives, delivery alternatives, current-held reversion and consumed delivery are tested.
- Full/partial stacks, capacity-failed reward, retry, NPC release/reassociation and wrong-NPC rejection are tested. Physical overlap with the production delayed pickup component acquires spawned loot.
- Actual Magis cast, projectile impact and successful status effect publish compatible events. Other NPC/dialogue/location/world flags and authority/owner isolation use the same route.
- Real Dialogic offer/ready sequences are cancelled: neither acceptance nor reward occurs, and movement returns. Natural timeline completion publishes its event.
- Atomic save/load restores state, selected quest, inventory, pickup receipts and reward ledger. Unknown version/item references reject without mutation; failed durable reward write rolls back values. Pending outbox replay and an interruption between claim and next-quest offering are recovered.
- A second Godot process loads an independently written file and rejects replayed pickup/reward claims. Both source and packed processes pass.
- All thirteen item IDs and four source mappings resolve. Production independent guaranteed/zero entries, random quantity bounds, repeated death, world coordinates, actual acquisition, explicit extra-drop bundles and rare stone configuration are checked. Seeded 160-roll runs per source demonstrate each configured item can emerge; this is reachability testing, not a statistical balance proof.
- Journal assertions check all fourteen rows, multi-target progress, locked prerequisites, reward preview and wrapping within an 800×600 layout.

## Play the field lab

```sh
/path/to/godot --path . res://scenes/tests/bakau-quest-test.tscn
```

Start beside the researcher and press E. Accept starting quests, fight monsters or use the safe debug controls, collect drops, return and hand in. Prerequisites unlock the remaining quests. Natural drop probabilities apply, so collection can take repeated encounters.

| Control | Action |
| --- | --- |
| E near researcher | Open resource-driven quest board |
| F1 / F2 / F3 / F4 | Spawn Snakehead / Dragonfly / Crab / Crocodile; live cap 16 |
| F5 | Refill health/mana |
| F6 | Deal actual lethal hitbox damage to live spawned enemies with player credit |
| F7 | Attempt real pickup of spawned drops; capacity/ownership still apply |
| F8 | Open board/journal |
| F9 / F10 | Save / restore supported quest/inventory progression |
| F11 | Toggle inventory readout |

F6/F7 do not directly write objective progress. Normal movement/combat and physical pickups also work. Platforms and a wall exercise the shared ground/LOS systems. Use `-- --quest-test-mode` to avoid automatic persistence while experimenting; explicit F9 still writes if requested.

A nonheadless OpenGL run with `--fixed-fps 60 --quit-after 150 -- --quest-test-mode --capture-bakau` produced `/tmp/magis-bakau-quests.png`; it was visually inspected at 1920×1080 for overlapping/clipped quest rows and details. The capture opens the board without injecting progress. The screenshot is a temporary review artifact, not a shipped game asset.

## Remaining verification boundary

No human full-length natural-drop playthrough, statistical balance study, browser/Windows packaged executable, real multiplayer session, power-loss filesystem test or final-art review was performed. Dragonfly is a fast ground-controller prototype rather than a flight/navigation implementation. Bakau content is playable through the dedicated field lab and reusable board, not placed into an unfinished production Bakau campaign map. General world saving, party loot and remote inventories remain outside this implementation.

## Mandatory NPC / offer / conversation extension

The final new suite runs **90 checks with zero failures**, from source, from a freshly converted PCK, and in a rendered OpenGL run. It adds real furniture/ground/region/approach/separation/fallback tests, actual physics wandering and one-step movement bounds, nearest/tie-broken interaction focus, blocked-wall rejection and readable marker layering. Each of the three real FLAC rooms is loaded and checked for configured counts, physical clearance and correct NPC-to-offer associations.

Every shipped quest uses the same native offer card and explicit validated decision. Tests cover portrait identity, title/dialogue/objective and actual item icon mapping, decline/reoffer/dismissal, single-use acceptance and owner/identity tampering. Real Dialogic introduction completion leaves the quest AVAILABLE; the native panel yields to the actual reaction timeline, and cancellation restores input. Source despawn, pause and Escape dismiss without acceptance. A live NPC reacquires its instance after save/load. The formerly broken generic talking-NPC template now uses the existing FLAC greeting, and its actual nonquest interaction closes without activating quests or changing scenes.

The phone checks use real Godot mouse input to open a contact and verify sender alignment, multi-quest cards, partial progress, milestone-only messages, retained completion/reward records, repeated save/load, read state and launcher Back. The separate persistence reader now also asserts that two explicit acceptance choices and read state survive a fresh process.

Fresh PCK verification clears only `.godot/exported`, Godot's generated resource-conversion cache. A stale conversion had silently omitted newly declared FLAC dialogue fields; rebuilding the cache preserves them. The full fresh export also exposed the talking template's missing old story path; that reference is repaired rather than ignored. All other runtime/script errors still fail the runner.

Rendered verification command:

```sh
DISPLAY=:0 /path/to/godot --path . --rendering-method gl_compatibility --fixed-fps 60 res://tests/quest-accessibility.tscn -- --quest-test-mode --capture-quest-ui
```

Eight actual rendered PNGs were produced and inspected under `/tmp/magis-quest-accessibility/`:

| File | Evidence |
| --- | --- |
| 01-flac-accessible-npc.png | Actual FLAC room, grounded NPC beside existing geometry, focused prompt and quest marker |
| 02-portrait-offer-objectives-rewards-actions.png | Centered native offer, Ariff's existing portrait, title/narrative/objectives, XP/currency icons, Accept/Decline |
| 03-declined-conversation.png | Real declined choice, configured NPC response, declined/reofferable card |
| 04-quest-contact-list.png | Avatar/name/preview/status/unread contact row at 448×640 |
| 05-accepted-conversation.png | Actual acceptance and NPC response with objective/reward card |
| 06-live-progress-conversation.png | Three actual Enemy V2 defeats reflected as Haruan 3/8 |
| 07-completed-reward-conversation.png | Eight defeats, actual hand-in, completed status and reward receipt |
| 08-embedded-phone-app.png | Quest messages inside the original phone viewport without a scene transition |

The screenshot generator does not assign fake objective progress: it uses actual offer decisions and production enemy hitbox defeats, then central hand-in. Contact images are rendered directly by a 448×640 SubViewport using the real app, and the final image uses the original PhoneUI scene. Captures are temporary review artifacts, not additional game art.

The implementation is verified for the configured static platform rooms and the Bakau field lab. Arbitrary multi-level navigation, dynamic furniture layouts, controller hardware, full multiplayer replication and a human campaign playthrough remain unverified. Existing resource shutdown diagnostics and provisional art/balance limits still apply. See the three new NPC/dialogue/conversation guides for authoring and supported boundaries.

## Corrected first-frame NPC spawning

The additional fresh-world fixtures reproduce a startup failure that the already-running-world tests missed. They launch each production FLAC room as the inherited main scene with ZoneRoot and the real player bootstrap enabled. Room one failed with zero NPCs before the timing fix; all three now pass four assertions each. Source and packed quest-only runs pass 285 assertions each, including the twelve new boot assertions. All three fresh-launch fixtures also pass on the user's installed Godot 4.7.2 Flatpak (12 assertions, zero failures). The normal-player-camera screenshot `/tmp/magis-npc-startup/npc-world-boot-1.png` was rendered and inspected. See the startup regression section in the accessibility guide.
