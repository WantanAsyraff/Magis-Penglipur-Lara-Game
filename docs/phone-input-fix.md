# Phone visibility and input handoff repair

Verified 2026-10-30 (Asia/Kuching), Godot 4.7.2.

The phone used to live under the overworld-only HUD. Combat hid that parent while phone input still toggled phone_selected, producing an invisible open phone that blocked pushback and interactions. The phone also checked phone_visible only at startup and only connected its apps when initially enabled. Finally, its fixed animation positions could place it outside a smaller viewport.

The phone is now a sibling of the combat/overworld HUDs in the production camera. It tracks story availability, dialogue, pause, restoration and modal ownership, clears selection/focus when disabled, suspends cached app input while closed and reconnects correctly after story unlocks. All apps connect independently of initial availability. Layout and animation endpoints fit the actual viewport; repeated toggles cancel the old tween. The phone animation reads the actual menu state instead of maintaining an independent key toggle.

Both worktrees now use **F for phone** and **E for NPC/object interactions**. Nearby interactions take priority over E pushback. F is no longer an alternative interaction key, avoiding conflicts with the phone. A visible, clickable F · Phone button sits at the bottom-right while the phone is closed; its hint follows keyboard rebinding. Stop and restart an existing play session after changing project input mappings.

The --actual-overworld fixture loads the production FLAC hallway, injects physical F to open/close the phone, checks onscreen bounds and clicks the actual launcher. Native verification (including crate inventory): 10 checks / 0 failures. Captures: docs/previews/phone-overworld-closed.png and phone-overworld-open.png.

Verification:

- tests/phone-and-push-input.tscn: 21 checks / 0 failures on environmental-interactions; 23 / 0 on inventory-v2 (adds inventory modal handoff).
- Native renderer run: 22 / 0 including viewport-fit checks at 1280×720 and 1920×1080. Images are in docs/previews/phone-input-1280x720.png and phone-input-1920x1080.png.
- live-spell-audit: 46 / 0; target-lock-and-hud: 37 / 0; target-lock-stability: 13 / 0; NPC world boot 1: 4 / 0.
- environment-interactions: 83 / 0; quest-accessibility: 90 / 0 on the active environmental branch.
- inventory-v2 core: 52 / 0; actual prologue/world integration: 20 / 0 on the inventory branch.
- git diff --check: clean. Existing resource shutdown diagnostics remain; the previously reproduced dialogue shutdown issue is unchanged.

Run the new regression from either worktree:

```bash
flatpak run org.godotengine.Godot --headless --path . tests/phone-and-push-input.tscn -- --quest-test-mode
```

Omit --headless and append --capture-phone to capture both viewport sizes. This fixture creates only process-local test state and does not write campaign saves. The quest-accessibility fixture now opens the phone before launching its app, matching the actual supported UI flow.

## Crate inventory and original phone preview

The separate Phone HUD button has been removed. The actual phone now rests with its top 80 pixels visible at the bottom-right, matching the original preview; F or clicking that preview slides it up. The preview height is exported for appearance tuning and still respects viewport scaling.

The crate Inventory app now routes through the phone handler (fullscreen=false), which opens InventoryOverlay and pauses the current world. It no longer switches scenes through App._on_clicked. A dangling App signal connection to a nonexistent method was removed. Inventory V2 and its item/equipment/save services are now present in the active environmental-interactions checkout as well as the inventory worktree. No branch merge or unrelated scene edits were performed.

Actual FLAC native fixture: 10 checks / 0 failures, including the resting preview, physical F, preview click, real crate-icon click, Inventory V2 visibility, same-world pause and closing/resume. Image: docs/previews/phone-crate-inventory.png. Inventory V2 core: 52 checks / 0 failures.

Active-checkout compatibility after inventory integration: quest pipeline 172/0, quest accessibility 90/0, environmental interactions 83/0, live spell audit 46/0, spell equipment UI 38/0, Save V1 writer/reader 60/0 and 20/0, environment persistence writer/reader 4/0 each. Existing resource-in-use diagnostics at engine shutdown remain.
