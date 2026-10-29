# Environmental visuals and animations

Every environment device uses [EnvironmentVisualData](../../data/environment/environment-visual-data.gd). Gameplay remains on the root, so replacing art preserves hitboxes, interaction rules, volume transfer and actuator links. Existing examples deliberately use original native Godot drawing: switch levers, gate bars, tank fill, rotating fan blades, receiver rings and turret barrels. Active, inactive, damaged, broken, charging and warning states are visible without external assets.

## Replace a texture

1. Import your PNG/SVG as a Godot Texture2D; choose nearest filtering for pixel artwork.
2. Make the device's data Resource unique, then create or make its `visual` Resource unique.
3. Assign `texture`, `offset`, `scale` and `tint`. Clear `frames` and `visual_scene` when selecting a simple texture.
4. Keep art centered on the root pivot. Set gameplay `size` independently; visual scaling does not resize collision.
5. Run the scene, toggle its state and verify collision is unchanged.

The included Visual child provides a procedural editor preview for reusable device scenes. Its exported `device`/`preview_active` are editor preview settings. Runtime always configures it from the root's data; after overriding data on an instance, assign the same data to Visual's preview slot to inspect the matching art in the editor. Runtime state owns animation timing.

## Animated sprites

Assign SpriteFrames to `visual.frames`. `InteractionVisual` creates AnimatedSprite2D automatically. Author animations named `idle`, `active` and `broken`, or change `idle_animation`, `active_animation` and `broken_animation`. A missing requested animation falls back to idle; if idle is also absent, the component keeps its native sprite frame without throwing a missing-animation error. Set loop and FPS in SpriteFrames. Use the idle frame for inactive state. Rotating fan and water simulation continue independently of animation playback.

## Custom visual scenes

For layered art, assign `visual_scene` with a Node2D root. It may contain Sprite2D, AnimatedSprite2D, polygons, lights and an AnimationPlayer child named exactly `AnimationPlayer`. The component drives its configured active/idle/broken animations, falling back to idle when necessary. Animate children of this visual root. Do not animate the gameplay root transform, collision disabled flags, water amounts, actuator state or player control.

Precedence is **custom PackedScene → SpriteFrames → Texture2D → native drawing**. A custom scene with an invalid root is rejected with a warning and native drawing remains available. To design richer state transitions, connect the root's `activated(bool)`/`broken` signals to your art adapter. Native turret warning/firing/charging indicators are temporary visual states; the shared default animation contract intentionally stays small.

## Audio and particles

Assign `activate_sound` and `deactivate_sound` AudioStreams. They play through an AudioStreamPlayer2D when effective output changes. Assign a one-shot GPUParticles2D/CPUParticles2D PackedScene to `particles`; activation starts it and its finished signal frees it. Looping or arbitrary particle scripts must manage their own lifetime. Water volumes independently accept splash particles and a surface Texture2D. Persistent restoration does not start a new Dialogic timeline.

## Crates and platforms

Floating crates expose `visual_data` directly; moving platforms use `MovingPlatformData.visual`. Both use the same configuration and fallback contract. Their authored collision shapes remain independent of the visual scene. Replacing a fan texture does not implicitly rotate the imported texture; animate its blades within the custom visual scene if needed. Native drawing rotates automatically.

## Verify artwork

The core suite exercises Texture2D, SpriteFrames with a missing active animation, a packed Node2D scene with AnimationPlayer fallback, and unchanged collision after art replacement. Compare real rendered [720p](../previews/environment/1280x720/station-01.png) and [1080p](../previews/environment/1920x1080/station-01.png) examples. Test source and exported PCK after importing a new asset; dynamic art paths must be included by the export preset. The native placeholders are functional defaults, not final production art.
