# NPC placement and interaction accessibility

## Placement policy

`NPCSpawnValidator` is a reusable Resource. RoomQuestManager exports a validator, `safe_spawn_markers` and `access_markers`. Marker positions represent desired feet positions; the validator projects downward onto collision layer 16, then places the body above that ground. The three FLAC F2 hallway rooms now contain authored safe and access markers and an explicit allowed region. Existing tile/furniture artwork and collision data are preserved.

The validator checks the entire body against the allowed region, configured obstacle margin, supporting ground at both feet, NPC separation and at least one clear full-height player approach lane. It also validates a sampled walkable corridor from an authored access marker on the same ground level. Solid furniture, walls and missing floor reject a route. Markers are tried first, then at most `max_attempts` random candidates, then a configured optional fallback. A fallback must pass the same checks. No valid result means a named warning and no spawn; there is no unsafe origin fallback or unbounded retry.

Dimensions are world units: the default 84×236 body envelope conservatively covers the existing scaled FLAC NPC shell. Clearance, interaction width, separation, solid mask, ground search and maximum step height are configurable. `allowed_region` is relative to the room spawner; marker NodePaths resolve to world positions. Access markers are authored reachable floor points, not arbitrary NPC instance positions. Keep them connected to player entrances when editing a room. The actual tested FLAC placements include (-1350,776), (3150,776), (2750,776), and room-two floor positions at y840.

The existing ground/side-view rooms do not provide a useful quest NPC navigation mesh. This implementation deliberately uses conservative local floor/collision validation. It does not invent a jump route or prove arbitrary multi-level reachability. Validate access markers when changing floor geometry; dynamic/moving platforms and elaborate navigation need their own policy.

## Movement ownership

Only `npc.gd` calls `move_and_slide()`, once per authoritative physics frame. WanderComponent supplies horizontal velocity through `steer(delta)`, never applies movement itself, and keeps a bounded target around its origin. Every proposed step validates region, body clearance, supporting floor, approach access, a local corridor and separation from nearby quest NPCs. Invalid movement pauses/reselects rather than walking into furniture or gaps. Configured stationary NPCs remain supported; normal FLAC quest NPCs retain wandering at 70 units/s within 180 units of their safe origin.

Room spawners establish faculty/identity and validated position before parenting, then configure the wander policy. Accepted/ready quests survive NPC release. Vacated room slots replenish after despawn; room cleanup preserves active/ready or busy NPCs so it cannot interrupt their hand-in dialogue. Replenishment is bounded and still uses the validator.

## Sorting and focus

The rooms use side-view tile layering rather than a top-down Y-sort navigation plane. Body z-index remains unchanged; the implementation does not lift every NPC above furniture. Existing intentional tile foreground/depth is retained. Quest indicators use z90 and interaction labels z100, independently of the body, keeping the existing marker readable over decorations. The native NPC sprite/body anchors remain unchanged and spawn height is grounded against the body envelope.

DetectionComponent chooses one focused candidate across all registered NPC/board detectors. It requires player range, an unobstructed layer-16 ray, movable gameplay state, no pause, no active Dialogic timeline, no offer and no selected phone. Nearest squared distance wins; equal distances use a stable node-path tie-break. Both accessible sides work. Only the focused detector shows its prompt or consumes the existing `interact` action. The board uses the same focus rules. An icon does not authorize interaction through a wall.

## Adding another room/NPC

1. Keep the existing NPC shell or configure the validator's body size for a different shell.
2. Add Marker2D safe feet positions beside furniture and access markers on reachable floor.
3. Assign a validator Resource with the allowed local region, margins, separation and bounded attempts.
4. Add the NPC PackedScene and stable identity to the room directory. Set faculty; provide NPCPresentation as described in the dialogue guide.
5. Run the accessibility suite and render the actual room. Test approach from both sides, doors/gaps and a fully blocked layout. A collision-free body alone is insufficient; a clear interaction route is required.

`tests/quest-accessibility.tscn` exercises synthetic solid furniture, invalid/clear fallback, ground/region/separation, real physics wandering, movement-step bounds, overlapping focus and wall blocking. It also loads all three actual FLAC room scenes and checks their configured NPC counts and clearance. Rendered evidence shows an approachable FLAC NPC, prompt and independent quest marker beside the existing room geometry.

## Fresh scene startup regression

A production-only failure was found after the initial tests: `physics_frame` fires before the physics step, so a spawner started with the main scene could query TileMapLayer before its initial collision shapes were synchronized. Every position was rejected and the spawner never populated. Earlier tests loaded room scenes into an already-running test world and did not catch this timing difference.

Startup now waits for the physics frame and its following process frame before checking placement. Three inherited main-scene fixtures (`tests/npc-world-boot-1.tscn` through `-3.tscn`) retain normal ZoneRoot/player initialization and exercise the first physics frames. Before the fix room one failed two of four assertions and logged both skipped NPCs. After the fix all twelve assertions pass across the three rooms on Godot 4.6.1, in the exported PCK, and on the installed Flatpak Godot 4.7.2. Bodies, sprites, collision/approach clearance and normal player creation are checked. The source/PCK quest runner now includes these fixtures.

A rendered normal-player-camera capture is available at `/tmp/magis-npc-startup/npc-world-boot-1.png`. It shows the player beside a freshly spawned NPC with the quest icon and E prompt. The capture moves the player near an NPC after verifying normal startup; it does not manually spawn or reposition NPCs. Restart an already running scene to execute its corrected initialization.
