# Inventory UI V2

The public [inventory-ui.tscn](../../scenes/ui/inventory/inventory-ui.tscn) path is retained. It instantiates native Godot Controls using [InventoryUI](../../scenes/ui/inventory/inventory-ui.gd), reusable [item rows](../../scenes/ui/inventory/item-list-row.tscn), presentation helpers and equipment drop targets. Data and quantities come from Inventory_Manager; the UI only sends validated manager actions. No hotbar or backpack-position model is introduced.

## Overlay and input ownership

InventoryOverlay opens a CanvasLayer over the current world using V or controller Back/Select. The phone's inventory shortcut closes the phone and opens this same overlay. SceneManager does not navigate away from the player. ModalService owns pause, previous mouse mode and focus; the UI processes while simulation pauses. Only its holder can release the pause. An already paused/exclusive interaction refuses opening, including dialogue, restoration, story movement reservations and transitions. Closing suppresses world-pause polling for two frames, preventing the same Escape press from reopening Pause. Save restoration cooperatively closes the overlay before rebuilding the world.

Player position and velocity remain in the original scene. Search text does not trigger V/Y shortcuts. Gameplay input cannot drive the pausable player while the overlay is open.

## Organization and refresh

The compact vertical list occupies about 60% of the body, with a scrolling details panel on the right. Inventory and Equipment have separate tabs. Category filters include All, Equipment, Consumables, Food, Materials (including weapon/rare materials), Components, Quest, Key and Favorites. Search matches name, description and stable ID without case sensitivity. Sort supports both name directions, category, quantity, authored Ringgit value and favorites first, with stable ID tie breakers. Value is metadata, not a newly implemented shop price.

Rows are cached by item_id. Inventory, equipment and preferences signals coalesce refreshes, update quantities and reconcile affected rows. Selection, scroll and search/filter state survive changes; removal selects a neighbor and restores useful focus. Details only show supported properties, plus disabled action reasons. Empty inventory and empty search results have distinct messages. Long descriptions and details scroll rather than expanding the whole window.

## Mouse, keyboard and controller

| Operation | Input |
| --- | --- |
| Open/close inventory | V / Back-Select; Close button; Escape or B closes |
| Navigate/select | UI directions (D-pad/stick), A / Enter, pointer |
| Favorite selected item | Y / controller Y, detail star |
| Previous/next tab | [ / ], LB / RB |
| Search | / or controller X; controller gets an on-screen keyboard |
| Filter/sort/actions | Focus native controls and use A / Enter |
| Confirm/cancel dialogs | A / Enter; B / Escape |
| Equip/unequip without dragging | Equip button → compatible slot chooser; select equipped slot → Unequip or Return to inventory |

Keyboard bindings are exposed in Settings. Rebinding keyboard keys preserves gamepad bindings. The existing ui_accept keyboard override now also includes gamepad A; ui_cancel includes B. Hardware mapping follows Godot's standard logical button indices.

Native Control drag data contains stable item IDs/slot identities. Dragging a held row reveals Equipment and accepts only a compatible slot. Dragging equipped gear onto Return to inventory unequips it. Preview/cancel never mutates inventory. The target rechecks ownership, exact current equipment, compatibility and capacity at drop time; stale drag metadata cannot authorize a transaction. Sorting controls row order; arbitrary visual backpack reordering is intentionally absent.

Child dialogs route controller cancel through window_input and restore focus. ScrollContainer follows focused rows, including the 64-item fixture. Controller routes are exercised through native input injection; physical-controller verification is pending when hardware is unavailable.

## Appearance and assets

Edit [inventory-theme.tres](../../assets/styles/inventory-theme.tres) for fonts, sizes and normal/hover/pressed/disabled/focus states. InventoryRow normal/selected styles are theme entries. InventoryUI exports background_color, optional background_texture, page_margin and optional open_sound/success_sound/failure_sound. Imported textures cover the viewport; null sounds stay silent. The opening fade lasts 0.12 seconds. Keep contrast and visible focus when supplying artwork. Item icons come from ItemData, fall back to readable monograms and use nearest filtering.

Layout uses anchors, Containers, stretch ratios and scrolling at 1280×720 and 1920×1080. Avoid increasing fixed dimensions until both resolutions are checked. Use the native [preview scene](../../scenes/inventory-testing/inventory-v2-preview.tscn) with --quest-test-mode --capture-inventory (add --720 for 720p). This creates scoped fixtures and captures real renderer images, not design mockups. See [validation evidence](../reference/inventory-v2-validation.md).
