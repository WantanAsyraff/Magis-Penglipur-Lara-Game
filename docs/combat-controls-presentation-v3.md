# Combat controls and presentation V3

Implemented on `feature/combat-controls-presentation-v3`, based on fetched main `b9ecee64256e181402e16087c4afbab5b52409ce`. Godot used for verification: **4.7.2 stable**, GL Compatibility. The working checkout is separate from the user's existing feature branch. No changes to spell IDs, authored sequences, costs, resolver strategy/rules, damage or equipment transactions.

## Controls and persistence

`system/input/control-bindings.gd` owns application-level binding snapshots, presets, category definitions, conflicts and typed persistence. `Player_Global_Data._ready()` loads it once; campaign loading does not reset it. Missing files leave the authored InputMap intact. Existing custom bindings remain Custom.

Settings edits a private `draft`. Preset selection, section reset and remapping cannot change gameplay until Apply saves and applies that draft. Cancel/closing discards the draft. Assistance is staged too. A failed assistance write restores the previously applied bindings/preference. Sections are Movement, Combat, Spellcasting and Interface, with content-only scrolling and a constrained 1000-pixel page width. Spellcasting advanced exposes Cancel Active Cast, Clear Sequence and Stop Movement. Interface advanced exposes any other registered non-UI actions, including future actions.

The existing `user://keybinds.cfg` path remains. Version 2 stores InputEvent class and storage properties, including physical/logical key codes, modifiers, device, joypad button/axis/value and mouse bindings. Old integer and keyboard-dictionary arrays still load; legacy keyboard-only records merge with existing nonkeyboard mappings. Unknown actions are skipped. Writes stage to `.tmp` and rename. Reset does not run on startup.

IJKL maps Up/Down/Left/Right to **physical I/K/J/L**. Arrow Keys maps these to physical **Up/Down/Left/Right**. Both replace keyboard events on only `incantation_up/down/left/right`, preserving their controller/mouse events and every other action, including built-in UI navigation. `ControlBindings.preset_name()` compares the actual keys, not a saved label. Remapping replaces the selected input family, retaining other device families. Capture consumes events, supports keyboard, mouse buttons, joypad buttons and axes, cancels with Escape/controller B, warns before a shared binding is accepted, and restores focus. Binding buttons show all configured events; long labels have tooltips.

To add another optional preset, add a name and four key constants in `ControlBindings.PRESETS`, in CAST_ACTIONS order. Settings discovers it automatically. The New Game panel currently authors explanatory card text for the two requested schemes; add a matching card diagram when extending that panel. Do not change movement or UI actions to add a casting preset.

## New Game

`save-slot-menu.gd` keeps profile/name selection and existing overwrite confirmation first. `_begin(overwrite)` opens `CastingPresetPanel`, without calling SaveManager. Back removes only the panel. Confirm saves/applies the four selected casting keys, locks the panel against duplicate submission, then calls the existing `SaveManager.new_game()`. An IJKL/Arrow saved mapping is preselected. A custom mapping displays a Custom message and requires choosing a card before confirmation. A clean installation uses the project's IJKL defaults. Empty character names are rejected before opening the panel. Load/Continue still call `_load()` directly.

The panel and controls page use a compact derivation of `generic-theme.tres`, with visible focus, selected and hover states. The player's unhandled combat input ignores visible GUI focus, dialogue, phone, quest offers and pause. Direction inputs are consumed in casting stance. UI arrow actions remain intact. The project's overridden ui_accept action gains its missing controller A binding so the cards and Settings can be activated with a controller.

## Magis effects

The production `IncantationInputParticles` scene remains attached to Player. Its script creates three reusable CPU emitters once, alongside the existing six-particle accepted-input emitter:

```text
Player
└── IncantationInputParticles (CPUParticles2D; controller + AcceptedInputBurst)
    ├── IdleAura (CPUParticles2D)
    ├── ComboFlow (CPUParticles2D)
    └── CastRelease (CPUParticles2D)
```

There are **74 default particles** (6 + 12 + 32 + 24). No emitter is allocated on keypress; bursts restart pooled emitters. Root quantity is clamped to 16 and each child to 64, giving an absolute configured bound of 208. There are no recurring timers. All emitters inherit pause and disappear with their player.

Stance activates a subtle outward/upward aura. Accepted directions increase capped buildup; rejected directions do not produce accepted bursts. Preparation/channel status adds gathering flow near the cast marker. Resolver clear/rebuild and cancellation reduce buildup; the player's explicit new-chain flag distinguishes a clear from the resolver's internal terminal reset, preserving accumulated terminal charge until launch. A completed shorter prefix releases a burst and retains reduced buildup when its branch remains active. Later queued requests keep their chain identity; an old chain's release does not erase a newer branch's charge.

`SpellCastingComponent.delivery_succeeded(context)` is a presentation-only observation emitted **after successful dispatch**. Projectiles release at launch; live channels release when their area/beam delivery starts, once, rather than after channel teardown. `cast_completed` remains unchanged for gameplay and weapon follow-through. Failed payment/validation/delivery never emits delivery success. Death immediately clears/hides effects; non-authoritative instances disable local feedback. The controller never changes resolver state, costs or requests.

Editable exports on `IncantationInputParticles`:

| Property | Default | Purpose |
|---|---:|---|
| intensity_scale | 1.0 | Combo intensity multiplier |
| direction_gain | 0.18 | Gain per accepted direction/preparation |
| fade_seconds | 0.35 | Smooth intensity transition |
| aura_quantity | 12 | Idle emitter quantity, capped 64 |
| flow_quantity | 32 | Flow quantity, capped 64 |
| release_quantity | 24 | Burst quantity, capped 64 |
| aura_lifetime | 0.8 | Continuous particle lifetime |
| drift_speed | 35 | Outward/upward initial speed |
| particle_size | 1.0 | Child particle scale |
| aura_radius | 65 | Emission radius around Yan |
| default_colour | muted cyan | Unresolved aura palette |

Replace the `texture` on the authored root CPU emitter to replace the soft dot across all four emitters. Its existing lifetime/speed/scale properties tune accepted-input pulses; the exported properties tune the child emitters. Release lifetime/speed and gathering acceleration are localized in the controller for future fine tuning. Known spell colors come from `SpellData.spell_colour`.

## Spell-path HUD

`IncantationAssistant` reads resolver snapshots and matching equipped spells after `changed`. The resolver is rebuilt by the existing equipped-repertoire synchronization. No separate Physics spell table exists. Unlearned/unequipped spells never enter the production player's repertoire.

Four cached groups contain a directional path, the actual `SpellData.spell_icon` **beneath** it, and a supporting name. Matching paths are ordered deterministically by resolver distance/name/ID, with the current exact match first. Entered directions are bold and underlined; remaining directions are muted. A check marks exact matches. Longer shared-prefix paths remain visible. Terminal reset restores root suggestions. Overflow is `+N`. Minimal shows two paths with a short entered/remaining context window and no names; Off hides optional guidance while existing success/failure text remains.

The root anchors bottom center, with a 112-pixel bottom margin. Height follows content; long single paths gain width and wrap into eight-direction lines without shrinking arrows. Groups and icons ignore mouse input. The old right-hand repertoire forecast defaults off (`show_legacy_repertoire`) to avoid duplicate guidance. Essential mana/failure text remains unchanged.

For a new spell, assign `spell_icon` on its registered SpellData Resource, register it through the established spell manifest/library, and use the existing learned/equipped APIs. The assistant discovers it automatically; null icons use the exported `fallback_icon`. `max_paths` is exported from 1–4. The HUD never calls push, confirm, clear or spell execution.

## Weapon assets and animations

The exact production attachment hierarchy is:

```text
Player
├── PlayerSprite (existing AnimatedSprite2D)
└── WeaponRig (Node2D, WeaponVisualController)
    ├── WeaponAttachment (Node2D, animated pivot)
    │   ├── WeaponVisual (Node2D, one asset instance)
    │   ├── WeaponHitOrigin (Marker2D, local 0,-48)
    │   └── WeaponEffectsOrigin (Marker2D, local 0,-52)
    └── WeaponAnimationPlayer (AnimationPlayer)
```

`WeaponVisualController.default_visual` supplies a geometric fallback for an equipped item without dedicated artwork; an empty slot is invisible. `ItemData.weapon_visual` references `WeaponVisualData`. Its exports are:

| Property | Default | Purpose |
|---|---|---|
| texture | null | Dedicated in-world texture |
| scene | null | Node2D asset scene; takes priority over texture |
| animations | null | Optional AnimationLibrary, installed under `asset` |
| offset | (24,-20) | Right facing grip position in player coordinates |
| rotation_degrees | -15 | Right facing rig angle |
| visual_scale | (1,1) | Asset-container scale |
| draw_order | 1 | Rig z_index |
| left_offset | (-24,-20) | Explicit left facing grip position |
| left_rotation_degrees | 15 | Explicit left facing angle |
| mirror_left | true | Mirror local attachment/effect/hit markers |
| effect_scene | null | Asset attached beneath WeaponEffectsOrigin |
| use_inventory_icon_fallback | false | Explicit opt-in to temporary icon art |

Position/rotation/facing live on WeaponRig; AnimationPlayer animates WeaponAttachment, so facing cannot overwrite animation tracks. The rig explicitly reads PlayerSprite.flip_h each frame; it does not rely on sprite flipping to mirror siblings. Walking/jumping/dashing move the rig with the player. Local inventory changes never attach a local weapon to a remote actor. Detached old actors ignore restoration signals.

The controller reads `Inventory_Manager.get_equipped(WEAPON)` at ready and listens to `equipment_changed`. Replacement removes the prior asset/effect once; repeated signals do not duplicate it. Existing SaveManager/QuestManager item-ID restoration re-emits equipment changes and reconstructs the rig. No second inventory or damage logic exists.

A registered `equipment_practice_magis_focus` item is available for authors/tests. It is not automatically granted to campaigns. Add it through the existing reward/pickup system, then equip through the existing WEAPON slot. Its geometric asset grants no stats or damage. The existing Inventory phone app now allows selecting an item and using Equip weapon / Unequip weapon. Both buttons call the existing authoritative manager APIs; inventory-full failures retain the current item. No second equipment store is introduced. Items with ItemType.EQUIPMENT and a WeaponVisualData resource expose the weapon action.

The editable AnimationLibrary in `weapon-rig.tscn` contains `weapon_idle`, `weapon_draw`, `weapon_holster`, `weapon_attack_1`, `weapon_attack_2`, `weapon_attack_air`, `weapon_block`, `weapon_parry`, and `weapon_cast`. Tracks rotate the attachment through real poses/swing arcs and return to idle. Holster hides the asset on completion; drawing shows it again. Existing push success triggers attack presentation, actual parry triggers parry presentation, block/stance select poses, and successful casts trigger follow-through. Main has no general melee attack signal: future attacks should call `WeaponRig.present_attack(index, airborne)` or `play_presentation(animation)` from their existing execution event. These methods do not create hits.

To replace artwork: create a WeaponVisualData Resource, assign a Node2D scene or dedicated texture, configure both facing offsets/angles and asset scale, then assign it to an ItemData with ItemType.EQUIPMENT. Register the item through `item-manifest.gd`. To replace animations: edit the named tracks in `weapon-rig.tscn`, or assign a per-weapon AnimationLibrary containing matching names. Asset tracks resolve from the WeaponRig root; target `WeaponAttachment` for poses and `WeaponAttachment/WeaponVisual` for appearance. Keep hit/effect markers editable. Body animations remain controlled only by PlayerAnim.

## Reproduction and evidence

Import once with Godot 4.7, then run:

```sh
python3 tools/test-combat-controls-v3.py --flatpak --capture
# Or, for a native installation:
python3 tools/test-combat-controls-v3.py --godot /path/to/godot --capture
```

The runner creates existing, isolated `v3-test-users-*` data directories beneath `.godot`, sets XDG/APPDATA inside Flatpak after its environment setup, and pairs persistence writer/readers in order. Test-prefixed campaign files and preferences are removed with those temporary directories. V3 tests refuse to run without both isolation and `--quest-test-mode`. Raw logs remain in `.godot/v3-test-results`. The capture option requires a real display and writes actual viewport PNGs under [previews/combat-controls-v3](previews/combat-controls-v3/).

The V3 integration suite opens the production New Game panel before creating a real prologue campaign; tests both control schemes against player input; exercises Settings draft/Apply/Cancel, physical/controller serialization, legacy merging, menu focus blocking, valid/invalid/prefix/terminal chains, live beam launch, failure/cancellation/death, actual weapon transactions/animations, and full campaign weapon save/load. Long authored paths, eight equipped definitions, missing icons and all assistance modes have explicit checks. The separate fresh-process reader verifies startup binding persistence.

The preview driver runs the production boss room and Player at 1280×720 and 1920×1080. It captures Settings, both preset cards, empty rig, initial aura, mid-combo, successful launch release, shared-prefix paths, equipped weapon, attack/cast placeholders, a 33-direction path, Minimal, Off and the production inventory weapon controls. Fifteen PNGs per resolution are inspected. Legacy projectile/impact placeholders appear during actual launch; they are cleaned from the capture fixture before inspecting weapon attachment poses. The new aura uses small CPU particles and does not require Forward+.

Final execution counts, diagnostics and file inventory are recorded in [verification/combat-controls-v3/results.md](verification/combat-controls-v3/results.md).

Limitations: physical controller hardware was not available; controller events/focus were exercised through the existing InputMap and scripted event paths. Dedicated weapon/body artwork and the existing large spell projectile/impact placeholders remain artist work. The sample focus needs the existing item pickup/reward flow or a test fixture; it is intentionally not a free campaign reward. Arbitrarily huge authored incantations can still occupy substantial vertical HUD space; the tested long path is 33 directions. Remote weapon equipment replication is outside this change; the rig avoids applying local inventory to remote actors. Regression logs retain existing UID, multiplayer-peer, stale collision-RID and resource-shutdown diagnostics; assertions and script errors are reported separately.
