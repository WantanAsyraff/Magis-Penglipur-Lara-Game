# Phone visibility and input handoff repair

Verified 2026-10-30 (Asia/Kuching), Godot 4.7.2.

The phone used to live under the overworld-only HUD. Combat hid that parent while phone input still toggled phone_selected, producing an invisible open phone that blocked pushback and interactions. The phone also checked phone_visible only at startup and only connected its apps when initially enabled. Finally, its fixed animation positions could place it outside a smaller viewport.

The phone is now a sibling of the combat/overworld HUDs in the production camera. It tracks story availability, dialogue, pause, restoration and modal ownership, clears selection/focus when disabled, suspends cached app input while closed and reconnects correctly after story unlocks. All apps connect independently of initial availability. Layout and animation endpoints fit the actual viewport; repeated toggles cancel the old tween. The phone animation reads the actual menu state instead of maintaining an independent key toggle.

Existing key bindings are preserved. The environmental-interactions worktree currently uses B for phone, F for interactions and E for pushback. The main-based inventory-v2 worktree uses F for phone, E for interactions and E for contextual pushback. In the latter, nearby interactions retain priority over pushing. Tests read configured phone/interaction keys and inject physical E for pushback.

Verification:

- tests/phone-and-push-input.tscn: 20 checks / 0 failures on environmental-interactions; 22 / 0 on inventory-v2 (adds inventory modal handoff).
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
