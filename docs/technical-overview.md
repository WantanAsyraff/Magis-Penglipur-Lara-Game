# Magis Penglipur Lara — Technical Documentation

**Status:** initial, living draft
**Engine:** Godot 4
**Doc owner:** Buffy assistant run at project root

This is the first pass of a technical reference for the Magis Penglipur Lara codebase. The README already calls for “resource building guides, high level system architecture, local APIs, standard of operations and common practises”, and this file starts that job from the current repository state rather than from a separate design doc.

## Purpose of this doc

This document is meant to be a practical map of the project as it exists today:
- what the game is trying to be
- how the codebase is laid out
- how major systems are wired together
- which conventions already show up in the source
- what is still incomplete and should not be treated as finished architecture

It is not a player-facing design doc. If something here disagrees with a later hand-written spec, the later spec wins, but this should make it easier to spot when the implementation has drifted.

## Project identity

Magis Penglipur Lara is a 2D RPG under active development. The application config names the project **“Magis Penglipur Lara”** and tags it as `flagship` and `rpg`.

The README frames Magis as a magic system where academic theory becomes practical spells through logic and creativity, described as “more than hogwarts but less than your average calculus exam.”

Even in a quick survey of the codebase, that framing is visible in the data model: spells, subjects, courses, and player progression are all tied together through a study/academic theme instead of a purely generic fantasy skill tree.

## Docs and roadmap state

- The README currently advertises technical documentation as **“coming soon.”**
- This file is the first operational draft meant to replace that placeholder, starting from the actual code and folder structure.
- The project already has a lot of working systems; what is missing is a consolidated explanation of them.

## Repository shape

The repo is structured like a Godot project first, with a few clearly separated concerns:

- `project.godot` — engine config, autoloads, dialogic setup, input, layer names, physics, rendering
- `autoloads/` — global singletons
- `components/` — reusable gameplay nodes and subsystems
- `data/` — resource definitions and content databases
- `dialogue/` — dialogic content and styles
- `scenes/` — world and UI scenes
- `system/` — low-level support like audio streaming and lyrics
- `tools/` — editor tooling

There is also:
- `addons/` with Dialogic, netfox internals, netfox Noray, and scene_manager
- asset folders under `assets/` for audio, fonts, icons, styles, tilemaps, UI, and so on

### Top-level layout conventions

Folder naming is already used as a rough content classification. For example, `project.godot` assigns editor folder colors to:
- `assets/`
- `assets/audio/`
- `autoloads/`
- `components/`
- `data/`
- `data/Resources/`
- `dialogue/`
- `scenes/`
- `scenes/ui/`
- `scenes/worlds/`
- `system/`
- `tools/`

That color scheme is a useful hint about how the team already thinks about the project, even before reading code.

## Engine config as architecture

`project.godot` is doing more than editor settings here. It effectively declares the core runtime architecture.

### Autoloads

The engine bootstraps a large set of global singletons, including:

- `Player_Global_Data`
- `Spell_Library`
- `Scene_Transition`
- `Player_Manager`
- `Network_Manager`
- `SceneManager`
- `Scene_Registry`
- `Dialogic`
- `Noray`
- `PacketHandshake`
- `World_Manifest`
- `QuestManager`
- `Inventory_Manager`
- `LyricsManager`
- `LyricsOverlay`
- `Crafting_Context`

A few things stand out immediately:
- player state, inventory, quests, spells, scene navigation, and networking are all elevated to global singletons
- netfox is integrated through both `Noray` and `PacketHandshake`
- dialogic is deeply embedded, not bolted on as an afterthought
- scene loading is routed through `SceneManager` rather than Godot’s default scene switch

So the high-level runtime already looks like a component-and-singleton game architecture rather than a single monolithic scene script.

### Dialogic config

The dialogic section of `project.godot` is substantial and shows how dialogue is wired:
- character definitions live under `dialogue/characters/`
- dialogue timelines live under `dialogue/quest/`, `dialogue/story-mode/`, and `dialogue/tutorials/`
- there is an explicit main style resource
- there are default variable entries like `CurrentPortrait` and `QuestText`
- there are detailed text-speed, choice, save, audio-channel, animation, and glossary settings

This suggests dialogue is not just cutscenes; it is a first-class part of quest flow and character interaction.

### Layer names

The project explicitly defines 2D render and physics layers:
- Player
- Enemies
- PlayerProjectiles
- EnemyProjectiles
- Environment
- UserInterface
- NPCs
- Drops

That is a strong clue about how collisions and rendering sorting are expected to work across the game.

### Input

The input map already includes:
- standard UI navigation
- game actions like interact, jump, block, dash-style movement, and incantation selection
- a dedicated `paused` action
- `casting_aim_lock`, `clear_incantation`, `god_mode`, and similar debug/utility actions

So both normal gameplay and development/debug usage are already present in the engine config.

### Rendering/physics

Notable settings include:
- 1920x1080 viewport
- viewport stretch mode
- high 2D gravity
- physics interpolation enabled
- GL compatibility rendering path

That is consistent with a 2D project that wants deterministic-feeling physics and broad platform compatibility.

## High-level architecture

The codebase can be read as several collaborating layers:

### 1. Global state layer

A set of autoloads owns persistent or cross-scene state:
- player identity/progression
- inventory
- quests
- spells
- scene registry
- network state
- world manifest
- crafting context
- lyrics
- scene transition coordination

This is the part of the architecture that keeps state alive across scene changes or at least makes it easy to reach from many systems.

### 2. Content data layer

Game content is mostly expressed as Godot resources:
- spells
- items
- quest data and objectives
- scene data
- courses and subjects
- loot definitions
- enemy/boss phase data

That is good architecture for an RPG: data-driven content with typed resources is easier to author and inspect than hardcoding the same info in scripts.

### 3. Scene and navigation layer

Scene flow is handled through:
- `SceneManager` for fade/loading transitions
- `Scene_Registry` for mapping `scene_id` to scene resources
- `World_Manifest` for discovering or baking world scene paths
- `Player_Manager` for player spawn/move/clear behavior

A few inferred rules:
- world scenes are expected to be registered by scene data resources
- scene IDs matter and are expected to behave like keys
- the player is spawned/managed separately from the scene itself

### 4. Dialogue layer

Dialogic is embedded as a major system, with:
- character dialogue timelines
- quest dialogue flow
- tutorial dialogue
- style and variable integration

There is also clear coupling between dialogue and quests via NPC components.

### 5. Combat and magic layer

Combat appears to revolve around:
- player magic projectiles
- enemy AI with detection, patrol, combat, and animation components
- hitbox-based damage and status application
- a spell library and incantation-style spell selection
- a spell tree UI for learning/equipping content

This is where the “magic meets theory” design is most visible, especially through spell data and the incantation map.

### 6. Network layer

There is multiplayer scaffolding around:
- hosting and joining over Noray
- handshake logic for UDP and ENet
- player spawn synchronization
- peer-connected/disconnected handling

### 7. UI layer

UI is spread across:
- overworld HUD
- combat UI
- inventory UI
- quest UI
- player stats UI
- spell repertoire/equipment UI
- menus: pause, settings, main, new-game, load, elevator, mission selection, music selection
- phone-like UI surfaces including e-hailing

The UI layer is clearly extensive and currently appears to be growing faster than any single unifying UI framework.

## Core systems

### Player global data

`Player_Global_Data` is the central player-state singleton.

What it owns includes:
- identity fields: name, role, mood, ringgit
- scene history: `previous_scene`, `current_scene`, `previous_position`
- goals/quest tracking
- flags: movable, jumpable, visible, hidden, invincible
- world name and world-changed signaling
- dash state with charges and max charges
- combat mode and casting mode with guarded setters and signals
- health and mana with clamped setters and change signals
- academic fields: current field/major/minor
- spell management: learned, equipped, add/remove/equip/unequip helpers
- mana/health helpers
- reset behavior

This singleton is basically the player’s runtime profile. Many other systems read from or signal into it.

One useful design note: it already uses guarded setters heavily for state that should broadcast changes, especially combat mode, casting state, mana, health, and dash charges. That is a good pattern to preserve.

### Spell library

`Spell_Library` scans `res://data/magis/spells/` for `SpellData` resources and builds:
- `all_spells` by spell id
- `incantation_map` from incantation sequence to spell

That means spells are effectively addressed two ways:
- by id
- by incantation sequence, as a comma-joined string

That fits a game where “casting” can be expressed as a sequence of directional/ritual inputs rather than only a menu selection.

### Player manager

`Player_Manager` handles player persistence across scenes in a multiplayer-aware way.

It knows about:
- the player scene
- a dictionary of players by peer id
- spawn logic by peer
- removal and clearing
- saving player position and current scene/position state
- local peer id from multiplayer if present

This is the layer that keeps “where is the player right now” from getting lost when scenes change.

### Scene registry and world manifest

`Scene_Registry` is basically a scene-id → `SceneData` lookup table.

`SceneData` itself carries:
- `scene_id`
- `scene` packed scene
- `scene_name`
- default spawn marker name
- description

`World_Manifest` is the boot-time glue that:
- scans `res://data/worlds/hubs/` for `.tres` scene data
- falls back to a baked path list if the scan fails
- registers those paths into `Scene_Registry`
- optionally validates scene IDs in debug builds

That validation is useful: it warns about empty IDs, uppercase letters, hyphens, and spaces. So scene IDs are already expected to follow a clean naming convention.

The baked manifest is generated by `tools/bake-world-manifest.gd`, which walks the same directory and writes `world-manifest-paths.gd`.

This is a practical offline/export-safe discovery pipeline: dev builds can scan, and exported or limited builds can fall back to the baked file.

### Quest system

The quest system is one of the more complete subsystems.

`QuestManager` loads `res://data/quests/flac-database.tres` and owns:
- quest start, accept, objective update, completion, hand-off
- NPC assignment by faculty and npc id
- per-quest active count limiting
- prerequisite and completion checks
- active goal text updates into `Player_Global_Data`
- despawn/expiry handling for abandoned available quests

`QuestInstance` is a runtime wrapper around `QuestData` with:
- status: available, active, complete, handed off, expired
- objective progress dictionary
- assigned npc id
- despawn timer support
- serialization to dict

`QuestData` carries:
- identity and description
- type, faculty, despawn time
- objectives
- rewards: XP, currency, loot
- prerequisite chaining and next-quest chaining

`QuestObjectiveData` supports:
- talk to npc, collect item, defeat enemy, reach location
- target ids and required amounts
- optional objectives
- prerequisite objective ordering

Quest NPC behavior lives in `QuestNPCComponent`, which handles:
- requesting a quest for an NPC
- dialogue-driven offer/accept/incomplete/complete flows
- dialogic integration
- portrait variable updates
- reward granting
- despawn and quest-manager hand-off

There is also an enemy quest observer pattern in `EnemyQuestObserver`, which notifies quest progress when certain enemies die.

So quests are not just UI labels; they are state machines with NPC assignment, objective progress, rewards, chaining, expiry, and enemy-driven updates.

### Inventory system

`Inventory_Manager` owns:
- a bag keyed by item id with quantity and item data
- equipment slots: weapon, offhand, robe, accessory 1, accessory 2
- add/remove/equip/unequip/pickup behavior
- quest objective hooks when items are picked up
- reset behavior

`ItemData` is a rich resource with:
- identity, icon, type, description
- stacking info
- economy value and sellability
- consumable effects: health restore, mana restore, exp reward, spell unlock
- quest objective ids
- recipe/ingredient fields for crafting

So items are already designed to participate in both inventory and quest/crafting economies.

### Combat and enemies

Enemy behavior looks component-based and fairly complete.

`Enemy` is a state machine with states:
- idle
- patrol
- chase
- attack
- hurt
- death
- return

It coordinates:
- hitbox component
- detection component
- patrol component
- combat component
- hurt timer
- animation playback

`HitboxComponent` is the main damage/effect receiver, with:
- damage calculation using reduction and multiplier
- knockback
- status effects: stun, slow, DOT, mana drain, silence
- effect tick/update
- invincibility and clearing effects

`EnemyDetection` handles:
- area connect
- line-of-sight raycast checks
- sight memory after losing the player

`EnemyPatrol` handles:
- home position
- patrol range
- wall jumps
- ground/cliff/enemy checks via raycasts
- return-to-home behavior

`EnemyCombat` handles:
- melee and ranged attacks
- cooldown timing
- chase velocity and retreat behavior
- LOS-checked ranged spell firing

There is also:
- `EnemyAnimationComponent` for attack-area-assisted animation triggers
- `EnemyLootComponent` for loot table drops with spread
- `DroppedItem` for physical loot pickups and inventory integration
- boss phase data for multiphase enemies

So combat is already split into sensible components rather than being one giant enemy script.

### Magic projectiles

`MagicProjectile` is the main projectile behavior.

It handles:
- lifetime based on speed and range
- visuals from spell data
- movement
- body collision with special handling for world/tiles
- piercing versus single-target behavior
- AOE shape queries around the impact point
- hitbox-based damage and effect application
- impact particles

The projectile system is one of the clearest examples of how spell data becomes runtime behavior.

### Spell tree UI

`SpellTreeView` presents courses/subjects as a layered subject graph.

It handles:
- building the field from course subjects
- computing depth from prerequisites
- locking subjects based on completed prerequisites
- cost calculation from comprehension, difficulty, and spell count
- opening a subject panel to learn spells
- refreshing lock states after learning

That fits the “study to unlock magic” framing very well.

### Dialogue integration

Dialogue is connected to gameplay through:
- `DialogicComponent` on NPCs
- `QuestNPCComponent` coordinating quest offers and completion dialogue
- `NPC._on_interacted()` choosing between dialogue and quest behavior
- quest NPCs updating Dialogic portrait variables

So dialogue is not isolated; it is one of the main interaction paths for NPCs and quests.

### Network and multiplayer

`NetworkManager` is the multiplayer facade.

It supports:
- hosting and joining
- Noray bootstrap and registration
- NAT and relay connect paths
- ENet server/client setup
- player spawn synchronization
- peer connect/disconnect handling
- RPCs for spawning and removing players

There is also:
- `Noray` as a netfox Noray client wrapper
- `PacketHandshake` for UDP/ENet handshake coordination

The important design detail is that local port handling is treated as critical: the code repeatedly notes that connectivity depends on using `Noray.local_port` correctly.

### Scene transitions

`SceneManager` is the addon-based transition controller.

It provides:
- fade in/out transitions
- scene loading with queued free/unload
- singleton entity tracking inside a scene
- reload and fade-in-place support
- configurable colors, speed, patterns, and callbacks

That means scene changes are not abrupt; they are expected to go through a transition layer.

### UI subsystems

UI appears to be built from many focused controls rather than one huge interface.

Notable pieces include:
- overworld HUD for goals, world name, dash display
- combat UI for health/mana/dashes
- inventory UI refreshing from inventory changes
- quest UI showing active quests and objectives
- player stats UI as a readout of many gameplay values
- spell repertoire panel for equipped spells
- menus for pause, settings, main, new game, load
- elevator UI, mission/story selection, music selection, phone UI, e-hailing UI, tutorial panels

Many UIs already connect to `Player_Global_Data` signals or `Inventory_Manager`/`QuestManager` signals, which is good for keeping them reactive.

### Audio and lyrics

There is a small but real audio subsystem:
- `AudioStreamPlayer` in `system/`
- a lyrics system under `system/lyrics/`
- `LyricsManager` and `LyricsOverlay` autoloads
- at least one music file and lyric text in assets

So lyrics/audio display is part of the project rather than an afterthought.

### Tools

There is at least one explicit editor tool:
- `tools/bake-world-manifest.gd`

It emits a warning in its output that the file name is `bake_world_manifest.gd`, but the actual file is `bake-world-manifest.gd`. That kind of mismatch is exactly the sort of thing technical docs should call out.

## Resource/data conventions

The project leans heavily on typed Godot resources. The main ones seen are:

- `SpellData`
- `ItemData`
- `QuestData`
- `QuestObjectiveData`
- `QuestInstance`
- `QuestDatabase`
- `LootData`
- `SceneData`
- `CourseData`
- `subjectData`
- `BossPhaseData`
- `BossAttackData`

A few conventions show up repeatedly:
- resource-based content for spells, items, quests, loot, and scene definitions
- explicit IDs rather than relying only on file names
- objective types and target ids for quest logic
- ingredient-style fields on items for crafting
- spell archetypes, comprehension levels, and categories for magis classification

That makes the content pipeline feel like a small data design rather than ad hoc script fields.

## Code conventions observed

From what is present, a few conventions are already forming:

- autoloads are treated as shared service points
- behavior is often split into components under entities
- signals are used heavily to keep systems loosely coupled
- guarded setters are used for state that should emit change events
- RayCast2D nodes are used for spatial queries and are often referenced by unique names
- `@onready` unique-name access is common for scene layout
- debug builds get extra validation and logging, especially around scene IDs
- there are explicit reset methods on major managers

There are also some inconsistencies that documentation should track:
- some scripts use `emit_signal(...)` style while others use `.emit(...)`
- some files use `print` heavily for flow debugging
- some systems are clearly more mature than others
- a few file names and referenced names do not match exactly

None of that is unusual for a live project, but it is worth recording so later work does not assume more uniformity than exists.

## Folder reference

### autoloads
Global singletons for player state, spells, scenes, quests, inventory, networking, world manifest, crafting context, lyrics, and transition support.

### components
Reusable gameplay building blocks:
- NPC components
- enemy components
- camera
- projectiles
- spell effects
- damage indicators
- dungeon interactivity
- platforms
- destructables
- elevators
- loot
- tilemaps
- panels

### data
Content and definitions:
- `Resources/` for spell/course/subject/scene data scripts
- `magis/` for spells and ilmiah/academic content
- `items/` for item data and item buckets like components and drops
- `quests/` for quest data, objectives, and databases
- `loot/` for loot definitions
- `npc/` for enemy related data and spawner/quest spawner scenes
- `tutorials/`, `worlds/`, and other content folders

### dialogue
Dialogic authoring content:
- characters
- glossaries
- overworld dialogue
- quest dialogue
- story-mode dialogue
- styles
- tutorials

### scenes
Runtime and UI scenes:
- world hubs and story scenes
- UI scenes for inventory, quests, spells, menus, HUD, phone, music, mission selection, and more
- spell tree and spell equipment scenes
- transitioners

### system
Lower-level support:
- audio stream player
- lyrics manager and overlay

### tools
Editor scripts:
- world manifest baker

### addons
Third-party/editor plugins:
- Dialogic
- netfox internals
- netfox Noray
- scene_manager

## Magic pipeline

The magic pipeline is the part of the project that connects theory/study content to actual spell behavior. Based on the code, it flows like this:

### 1. Author spell and study data

Spells are authored as `SpellData` resources in `data/magis/spells/`.

Study content is authored as:
- `subjectData`
- `CourseData`
- related spell data

That gives the game a vocabulary of spells plus a study structure around them.

### 2. Load spells into the library

At runtime, `Spell_Library` loads all `.tres` files from the spells directory and indexes them by:
- spell id
- incantation sequence

That means spell authoring is not just art/design data; it also directly feeds runtime lookups.

### 3. Player learns and equips spells

Through `Player_Global_Data`, the player can:
- learn spells
- equip spells
- unequip spells
- query learned/equipped status

Spell learning can come from:
- items with `spell_to_unlock`
- the spell tree UI when a subject is completed

So spells enter the player’s repertoire through multiple paths.

### 4. Player selects/casts spells

The casting path appears to involve:
- a selected spell in player data
- a spell repertoire/casting UI
- incantation-style input sequences
- combat mode changes that affect UI visibility and behavior

The incantation map suggests that spell selection can be performed through ordered input sequences rather than only clicking a spell in a list.

### 5. Spell becomes a projectile/effect

When a spell fires, the projectile system uses `SpellData` to decide:
- speed, range, size
- damage and AOE radius
- knockback, status effects, DOT, mana drain, silence, and similar effects
- visuals and particles
- piercing behavior
- self-cast vs targeted behavior
- sound and impact behavior

So the same data drives both UI and runtime behavior.

### 6. Target receives the spell through hitbox effects

When a spell hits something with a `HitboxComponent`, that component applies:
- damage
- knockback
- status effects according to spell flags and durations

That means magic impact is handled through the same effect pipeline used by other sources, which keeps combat behavior consistent.

### 7. Study content gates and explains spells

The spell tree uses course/subject data to:
- lay out subjects by prerequisite depth
- compute learning cost
- lock subjects until prerequisites are met
- reflect learned spells back into lock state

That ties magic progression back to the academic theme: unlocking spells is framed as completing study subjects, not just picking skills from a flat list.

### 8. Magis classification adds flavor and possibly gameplay tuning

Spell data already carries:
- magis archetype
- magis comprehension
- spell category
- spell type and manifest
- resonance and off-archetype tuning fields

Even if some of those fields are still partially aspirational, they show the intended shape of the magic system: spells are categorized, graded, and tuned relative to archetypes.

## Content authoring pipeline

Although not every piece is fully documented in-code, the authoring flow can already be inferred.

### World/content flow

1. Create or edit a world scene under `scenes/worlds/` or `scenes/worlds/hubs/...`
2. Author a matching `SceneData` resource so the scene can be registered by ID
3. Place the scene data under `data/worlds/hubs/...`
4. Let `World_Manifest` discover it, or regenerate the baked manifest for export safety

### Quest flow

1. Define objectives as `QuestObjectiveData`
2. Define a `QuestData` with rewards, prerequisites, and objectives
3. Add it to a `QuestDatabase`
4. Assign NPCs by faculty/npc id
5. Let `QuestManager` handle offer, accept, progress, completion, and hand-off

### Item flow

1. Author `ItemData`
2. Set stacking, economy, effects, quest hooks, and optional recipe ingredients
3. Use it in loot tables, drops, or quest rewards
4. Let `Inventory_Manager` handle pickup and equipment

### Enemy flow

1. Build an enemy scene with the expected component layout
2. Set stats, detection, patrol, combat, animation, loot, and optional quest observer data
3. Optionally use boss phase data for multiphase fights
4. Place spawners where needed

### Dialogue flow

1. Define characters and dialogue timelines in dialogic
2. Wire NPC dialogue/quest components to those characters
3. Use quest dialogue for offer/incomplete/complete flows
4. Update portrait and variable state from gameplay when needed

## Open concerns and likely next doc sections

The following are visible gaps or rough edges that the documentation should eventually address explicitly:

- Save system: the pause menu already says save is not yet implemented
- Crafting context exists but is currently very sparse
- Some UI pieces are clearly more mature than others
- There are multiple networking-related autoloads, and their exact responsibilities should be written down precisely
- Some spell fields may be partially implemented or still awaiting downstream systems
- Tooling names and referenced names should be reconciled
- There should be a clearer explanation of how scene IDs, scene registry, and world manifest are supposed to stay in sync
- The relationship between `Player_Global_Data`, `Player_Manager`, and `SceneManager` should be documented more explicitly for future contributors

## Conventions for future technical docs

Once this draft is in place, later documentation should probably follow the same practical rules:
- describe what the code actually does, not just what the design aspiration is
- favor resource paths, autoload names, signal names, and scene node roles over vague descriptions
- call out unfinished parts plainly
- record conventions only after seeing them repeated in the codebase

## How to use this file

Treat this as the root technical doc for the repository. When a subsystem becomes stable enough, give it its own section here or a dedicated file and link it from here. Until then, this is the place to record architecture, pipelines, conventions, and known gaps.

