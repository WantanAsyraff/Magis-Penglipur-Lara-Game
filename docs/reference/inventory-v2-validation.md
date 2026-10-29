# Inventory V2 and prologue cutscene delivery

Verified 2026-10-29, Asia/Kuching, with Godot 4.7.2.stable.flathub.ed1daf0bf. Functional assertions are distinguished from process shutdown status below. No push or merge was performed.

## 1. Branch and commits

Branch: feature/inventory-v2-cutscene-skip. Base: b9ecee64256e181402e16087c4afbab5b52409ce (fetched origin/main). Implementation commit: f8e8f7faa45d30bbef321bec2279768d520ca8b7. Documentation/evidence is the following commit; resolve it with git log -1 on this branch.

Worktree: /home/wantansirap/Projects/Magis-Penglipur-Lara-Game-inventory-v2. The original environmental-interactions worktree remains on its existing branch, with its user-owned project.godot and spell-testing.tscn edits preserved. Those unrelated changes were not transplanted over the requested main base.

## 2. Files created or modified

Runtime additions: ModalService, InventoryOverlay and CutsceneFlow autoload scripts; ItemActionResult; responsive story dialogue layout; CutsceneSequence plus three authored Resources; registered student lab robe; inventory Theme, row scene/script, presentation helpers and equipment drop target; native inventory preview scene. Corresponding Godot script UIDs are included.

Runtime modifications: inventory-manager, quest-manager, save-manager; camera pause integration; dropped-item and pickup component; quest objective evaluator and save service; ItemData and item manifest; inventory UI scene/script; phone shortcut and Settings rebinding; project autoload/input mappings; three terminal timeline signals; house, school, subway and FLAC entrance controllers. Vendor addon files and unrelated combat/spell gameplay are unchanged.

Verification additions: inventory-v2, inventory-v2-save, cutscene-skip, prologue-inventory-integration scenes/scripts; native inventory-v2-gameplay script; three timeline fixtures. Existing combat-feedback-save-v1 fixtures now use genuinely compatible equipment and restore the pre-test multiplayer peer. Documentation adds three authoring guides, this report, extracted results and 28 native screenshots; updates handbook indexes, loot guide, registration/testing/property references and validate-docs.py Resource-guide coverage.

See the [complete changed-file inventory](inventory-v2-files.txt) for every added/modified path, including UIDs and screenshots. git show --stat on each commit provides the corresponding review summary.

## 3. Inventory architecture

The existing public inventory-ui.tscn path now hosts a fullscreen native Control menu. Cached item_id-keyed rows derive quantities from Inventory_Manager. The left list uses roughly 60% of the body; the right details area and long text scroll. Inventory and Equipment tabs remain distinct. Filters cover every existing category, with weapon/rare materials grouped under Materials. Search matches name/description/ID without case sensitivity. Six presentation sorts use stable ID ties. Changes coalesce refreshes and preserve selection, scroll and focus; removed selections choose a neighbor.

## 4. Use and equipment behavior

Fish Meat is stored without auto-healing and heals only on successful manual Use. Full health/mana rejects ordinary waste; effects clamp through existing stat APIs. ItemData.use_behavior separates compatibility/manual/acquisition/none semantics. Compatibility/acquisition XP and spells award once per identity using existing receipts; explicit manual XP consumes one item per award. Named components receive no invented effects.

Five equipment slots retain their identities. Optional typed mask flags authorize new equips; manager-level transaction preflight validates ownership, compatibility, capacity and replacement return atomically. Legacy zero-mask saved equipment remains loadable and removable. No fictional weapon/armor statistics or campaign fixture grants are introduced.

## 5. Fullscreen pause

InventoryOverlay uses a CanvasLayer over the same scene. ModalService owns pause, mouse mode and previous focus. Always-processing UI remains responsive; the actual player scene/position/velocity stays paused. Dialogue, transition, restore, reserved movement, existing pause and incompatible modals reject opening. The phone shortcut routes to this overlay. Escape close suppresses the same event from reopening world Pause. Save restoration closes/relinquishes overlays before replacing worlds.

## 6. Drag and drop

Native Control drag APIs provide a floating item preview and compatible/invalid target highlighting. Starting a held-item drag reveals Equipment. Drop targets revalidate stable IDs, current quantities, exact source equipment and slot compatibility; only the manager commits. Returning equipped gear uses the same atomic unequip path. Cancellation leaves source state intact. There is no physical backpack-position rewrite.

## 7. Controller support and limits

Back/Select opens; B closes/cancels; A selects/confirms; Y toggles favorite; LB/RB switch tabs; X opens a navigable on-screen search keyboard. D-pad/stick UI actions navigate rows, actions and native filter/sort popups. Equip has a compatible-slot chooser; Unequip and Return supply drag equivalents. Focus survives quantity changes, removal, dialogs and long-list scrolling. Settings preserves gamepad bindings when rebinding keyboard keys.

Native input injection verified the implemented controller routes. Input.get_connected_joypads returned an empty array. **Physical-controller manual verification remains pending**; no hardware PASS is claimed.

## 8. World drops

Drop confirms a chosen stack quantity. Protected quest/key items and can_drop=false items reject it. Safe shape/line checks and a live authoritative player are required. The actual existing DroppedItem scene is created once; failed spawn/search preserves inventory. Fresh player drops wait 0.8 seconds and for the player to move over 500 world units away before collecting. Reclaim consumes a ledger token once and cannot replay acquisition rewards or cumulative quest credit.

Chosen Save V1 policy: dropped quantities reserve their original ID/stack capacity and return once on area exit or load. World-drop positions are not persisted. This prevents loss and recovery-capacity races; **dropping does not permanently discard an item or free reserved capacity**. The confirmation, result and capacity display explain the policy.

## 9. Favorites

Favorites use stable IDs, with star/Y/controller actions. Optional profile-scoped favorites live in the existing Quest V2 payload. Fresh-process load restores them; new profile/reset clears them. No global preferences leak between profiles. Selection/search/scroll remain transient UI state.

## 10. Save V1 compatibility

GameSaveSchema stays VERSION 1 and QuestSaveService stays VERSION 2. Optional favorites/drop_escrow fields default safely for old saves. Staging rejects malformed IDs/tokens, fractional/excess quantities, corrupt favorites and explicit incompatible slots before mutation. Restore returns valid escrow once, reconciles held objectives and preserves prior ledger state on rollback. Existing autosave/manual/death recovery/corrupt-save/authority coverage ran through the Save V1 writer/reader.

## 11. Cutscene skipping

CutsceneSequence is opt-in and contains stable ID, authored timeline, style, terminal signal, completion context, optional canonical spell and authored recap. CutsceneFlow tracks the exact owner/timeline and distinguishes NATURAL, SKIPPED and INTERRUPTED. Natural terminal completion and deliberate skip apply the same required effects once; interruption never awards progress. Completion uses existing world_flags and autosave. Completed sequences do not replay or overwrite later spell equipment.

F1/R3 or mouse hold for 0.8 seconds drives visible progress; release/focus loss cancels. The key is remappable. Dialogue advance, Escape and Back do not skip. Any authored choice or jump blocks skipping conservatively, including future mandatory choices; current choice/quest-offer states also reject it. Ordinary NPC dialogue gains no skip action. Optional recap uses its own modal ownership and is dismissed by inventory, restore or transitions.

## 12. Prologue integration

House completion restores movement/noncombat without touching unrelated Yunira content. School restores combat and grants/equips only Kinetic Chill once, leaving the practical examination scene and portal/gameplay intact. After-final-paper is used by both subway and FLAC entrance: neither receives an invented reward/transition; FLAC retains phone visibility while subway retains its original hidden-phone context. A story-only responsive layout reserves the lower-right skip gutter without changing ordinary main-style NPC layouts.

## 13. Automated commands and results

All gameplay commands use --quest-test-mode and isolated test-prefixed profiles. The source commands below run from the new worktree; see [testing instructions](testing-and-validation.md) for the complete existing regression commands. Save writers run before their readers; fixtures sharing profiles run sequentially.

```bash
flatpak run org.godotengine.Godot --headless --path . tests/inventory-v2.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/cutscene-skip.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/inventory-v2-save.tscn -- --quest-test-mode
flatpak run org.godotengine.Godot --headless --path . tests/inventory-v2-save.tscn -- --quest-test-mode --read-inventory-save
flatpak run org.godotengine.Godot --headless --path . --editor --import --quit
flatpak run org.godotengine.Godot --headless --path . --export-pack Web /home/wantansirap/.cache/magis-inventory-check/inventory.pck
GODOT_COMMAND='flatpak run org.godotengine.Godot' python3 tools/validate-docs.py --write-reference --check-gdscript --check-resources
```

| Source suite | Assertions / failures | Process result |
| --- | --- | --- |
| inventory-v2 | 52 / 0 | Exit 0; existing resource shutdown diagnostic |
| cutscene-skip | 28 / 0 | All assertions complete; baseline dialogue shutdown abort (134) |
| inventory-v2-save writer / reader | 8 / 0; 10 / 0 | Writer completes assertions then baseline dialogue shutdown abort; reader exit 0 |
| native inventory gameplay, each resolution | 36 / 0 | Includes 12 renderer captures; baseline dialogue shutdown abort after marker |
| actual four-world integration, each resolution | 22 / 0 | Includes two real-world captures; baseline dialogue shutdown abort after marker |
| quest pipeline / accessibility | 172 / 0; 90 / 0 | Exit 0 |
| quest persistence writer / reader | 4 / 0; 7 / 0 | Exit 0 |
| combat feedback / Save V1 writer / reader | 60 / 0; 20 / 0 | Exit 0 |
| spell equipment UI | 38 / 0 | Exit 0 |
| spell regression / live spell audit | 71 / 0; 46 / 0 | Exit 0 |
| player combos / incantation assistant | 23 / 0; 60 / 0 | Exit 0 |
| enemy pipeline / boss prototype | 138 / 0; 70 / 0 | Exit 0 |
| target lock HUD / stability | 37 / 0; 13 / 0 | Exit 0 |
| physics curriculum | 272 / 0 | Exit 0 |
| NPC world boots 1, 2, 3 | 4 / 0 each | Exit 0 |

Crafting is exercised through actual CraftingUI transaction processing in inventory-v2, including stored food without pickup healing. Core coverage also includes blocked spawn, real recoverable stack, area exit recovery, legacy equipment, fractional save rejection, cumulative objective anti-farming, capacity and focus after last-stack removal.

Exported native pack: inventory-v2 52/0 (exit 0), cutscene-skip 28/0 (shutdown 134), inventory save writer 8/0 (shutdown 134) and reader 10/0 (exit 0), actual-world integration 20/0 without screenshot assertions (shutdown 134). Editor import and Web PCK export exit 0. Handbook checks cover 43 Resource classes and 422 properties, two executable snippets and two Resource examples, with zero validation errors.

Exported-pack results and final handbook checks are recorded in [extracted test output](inventory-v2-test-results.txt). Export is a resource-reachability/native-pack check, not a browser deployment claim. No justfile is present; git diff --check is the final whitespace check.

## 14. Actual gameplay verification

Both native renderer fixtures were launched at 1280×720 and 1920×1080. The inventory fixture uses the actual production Player and manager/UI, injects native mouse drags, cancels/releases them, equips/unequips, uses real consumables, navigates native gamepad routes and holds the actual mouse skip button. It covers zero/few/64 items, several categories, favorites, missing icons, long names/descriptions and search-empty states.

The world integration fixture loads the actual house, school, subway and FLAC entrance scenes and their real controllers. It verifies inventory restrictions during story, movement/combat/phone completion context and that no extra transition occurs. It opens/closes inventory over the actual house, preserving the scene/position/pause, and verifies the school learns only thermal_01 (Kinetic Chill). This is automated native integration plus screenshot inspection, not a claimed human end-to-end campaign playthrough.

## 15. Screenshots

Each directory contains 14 actual renderer captures: empty, populated, equipment, controller search keyboard, no results, favorites, long description, quantity confirmation, 64-item capacity, eligible skip, partial hold, resumed gameplay, actual house inventory and actual school gameplay.

| Example | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Compact inventory | [720p](../previews/inventory-v2/1280x720/02-items.png) | [1080p](../previews/inventory-v2/1920x1080/02-items.png) |
| Equipment | [720p](../previews/inventory-v2/1280x720/03-equipment.png) | [1080p](../previews/inventory-v2/1920x1080/03-equipment.png) |
| Drop confirmation | [720p](../previews/inventory-v2/1280x720/08-drop-confirmation.png) | [1080p](../previews/inventory-v2/1920x1080/08-drop-confirmation.png) |
| Maximum capacity | [720p](../previews/inventory-v2/1280x720/09-capacity.png) | [1080p](../previews/inventory-v2/1920x1080/09-capacity.png) |
| Hold progress | [720p](../previews/inventory-v2/1280x720/11-skip-hold.png) | [1080p](../previews/inventory-v2/1920x1080/11-skip-hold.png) |
| Actual house inventory | [720p](../previews/inventory-v2/1280x720/13-actual-house-inventory.png) | [1080p](../previews/inventory-v2/1920x1080/13-actual-house-inventory.png) |
| Actual school continuation | [720p](../previews/inventory-v2/1280x720/14-actual-school-gameplay.png) | [1080p](../previews/inventory-v2/1920x1080/14-actual-school-gameplay.png) |

## 16. Known limitations and diagnostics

Physical-controller manual testing is pending. Player drops use the documented reserve/return policy rather than persistent world litter or permanent disposal. Existing zero-mask legacy equipment is preserved on load but cannot be newly equipped. New cutscene effects beyond the existing context/spell contract require tested integration; branching/jump sequences are conservatively non-skippable. UI scaling was checked at the two requested resolutions, not every ultrawide/mobile size. No new gear statistics, shop, hotbar or persistent recap journal is claimed.

Existing UID fallback/world-ID warnings and 25 resources in use at shutdown remain. More significantly, the installed engine aborts at process shutdown after running dialogue, even when every assertion has completed. This was reproduced in a separate pristine b9ecee6 archive after editor import, with only a diagnostic fixture that starts spm-school-entrance directly, waits, calls Dialogic.end_timeline(true), waits again and quits. It uses neither the new CutsceneFlow nor inventory code. A local core trace reaches pthread_mutex_lock during engine teardown. Vendor changes and engine replacement were outside this task. Dialogue test assertion success is therefore **not** reported as clean process-exit PASS. Runtime interactions and scene cleanup completed before this existing shutdown failure.

## 17. Future content authoring

Use [inventory and items](../authoring/inventory-and-items.md) for new registered IDs, effect behavior, slot flags and safe drops; [inventory UI](../authoring/inventory-ui.md) for themes, icons, sounds and controls; [cutscene skipping](../authoring/cutscene-skipping.md) for explicit contracts and terminal markers. Register canonical spell dependencies, retain stable published IDs, test exported reachability and run fresh-process saves. Do not put fixture item grants into campaign scenes. Before release, complete a physical-gamepad pass and investigate the reproduced engine/vendor dialogue shutdown issue against the chosen shipping engine build.
