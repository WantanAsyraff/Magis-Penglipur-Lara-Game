# Magis Pipeline

This documents how magic content and spell behavior flow through the project, from authored data to runtime combat and progression.

It is part of the technical documentation for Magis Penglipur Lara and is meant to describe the current implementation, not just the intended design.

## Overview

The Magis pipeline has three main jobs:

1. turn authored spell and study data into runtime spell definitions
2. let the player learn, equip, and cast those spells
3. resolve spell effects through the same hitbox and status pipeline used by other combat interactions

In other words, magic is not a separate silo. It is stitched into the same systems that handle enemies, items, quests, and UI.

## Data layer

### Spell data

Spells are authored as `SpellData` resources, currently found under:

- `data/magis/spells/`

Example files include:

- `phys-collapse.tres`
- `phys-crash.tres`
- `phys-force.tres`
- `phys-resonate.tres`
- `phys-shatterwave.tres`
- `phys-strike.tres`
- `phys-terminal.tres`
- `thermal-kinetic.tres`

`SpellData` carries a large amount of classification and behavior data, including:

- category: projectile, AOE, healing, buff, decast
- identity: name, id, icon, color, flavor text, theory description
- classification: spell type, spell manifest, magis archetype, magis comprehension
- incantation sequence
- mana cost and channeling details
- projectile fields: scene, texture, particles, sounds, range, size, damage, speed, spread, piercing, self-cast flag
- AOE fields: radius, explosive force, knockback force
- healing fields: flat heal, HoT flag, tick heal, tick interval, HoT duration
- buff fields: buff type, magnitude, duration, stacking
- decast fields: mode, radius, purge behavior, misfire silence
- tether/chain fields: chain range, max targets, damage falloff, equilibrium bias
- status effect flags: stun, DOT, slow, mana drain, silence
- a placeholder hook for future status effect resources

That is a lot of data for one resource, but it also means spells are the main bridge between design intent and runtime behavior.

### Study data

Study content is authored as:

- `subjectData`
- `CourseData`

These live under:

- `data/Resources/ilmu/`

`subjectData` includes:

- name, id, icon
- subject archetype
- field of study, theoretical foundation, caster notes
- magis archetype and comprehension
- difficulty level
- prerequisites
- contained spells

`CourseData` includes:

- course name, id, archetype
- description
- magis archetype and comprehension
- difficulty level
- prerequisites
- subjects

So spells are not just a flat list. They can be grouped into subjects and courses, which is what gives the magic system its academic structure.

## Spell library loading

At runtime, `Spell_Library` does two things:

1. scans `res://data/magis/spells/` for `.tres` files and loads them as `SpellData`
2. builds an incantation map from the spell’s incantation sequence to the spell resource

The result is two lookup paths:

- by spell id
- by incantation sequence, stored as a comma-joined string

That means a spell can be found either by its identifier or by the input sequence used to cast it.

The loader is intentionally directory-driven. If you author a new spell resource and drop it into the spells folder, it should become part of the library automatically.

## Learning and equipment

### How spells enter the player’s repertoire

The player does not start with every spell. Spells enter the repertoire through:

- `Player_Global_Data.learned_spells`
- `Player_Global_Data.equipped_spells`

Learning can happen from:

- items that carry `spell_to_unlock`
- the spell tree UI when a subject is completed

### Player spell management

`Player_Global_Data` provides:

- `add_spell`
- `add_spells`
- `remove_spell`
- `has_spell`
- `equip_spell`
- `unequip_spell`
- `is_spell_equipped`

Learning and equipping both emit `spells_updated`, which is how UI panels stay in sync.

There is also a transient `selected_spell` field on `Player_Global_Data`, which suggests spell selection can be tracked separately from permanent learning.

## Incantation casting path

One of the more distinct parts of the pipeline is that spells can be addressed by an incantation sequence.

The sequence is stored as an `Array[String]` on `SpellData`, and `Spell_Library` converts it into a lookup key like:

- `down,down,right,up`

That implies a casting model where the player performs a sequence of directional or ritual inputs and the game resolves it to a spell.

The relevant runtime pieces are:

- `Spell_Library.incantation_map`
- `Spell_Library.get_spell_by_incantation`
- `Player_Global_Data.selected_spell`

So the casting pipeline is not just “click a spell icon.” There is also a path for sequence-based spell selection.

## Combat spell execution

Once a spell is selected or triggered, it flows into the same combat pipeline used by other attacks.

### Projectile behavior

`MagicProjectile` is the main spell projectile behavior. It reads `SpellData` and uses it to determine:

- visuals and scale
- lifetime from range and speed
- movement direction and speed
- collision behavior
- piercing vs single-target behavior
- AOE radius and shape query
- impact particles
- sound/visual hooks from spell data

Important runtime behavior includes:

- the projectile tracks its source
- it skips hitting its source
- it treats world/tile hits as terminal impacts
- it supports piercing through already-hit bodies
- it applies AOE around the hit point when the spell has a radius
- it calls `HitboxComponent.receive_hit` on eligible targets

So a spell’s data fields are not just flavor; they directly control movement, impact, and area behavior.

### Hitbox and status effects

When a spell hits an entity with a `HitboxComponent`, the spell’s effects are applied through that component.

`HitboxComponent.receive_hit` handles:

- damage from `projectile_damage`
- knockback from `knockback_force`
- stun
- slow
- DOT
- mana drain
- silence

Status effects are tracked internally and ticked over time, with expiration behavior for each active effect.

That means the magic system reuses the same effect pipeline as other combat interactions, which keeps damage and debuff resolution consistent.

### Enemy spell usage

Enemies can also participate in the magic pipeline.

`EnemyCombat` supports ranged attacks that can spawn a spell projectile from:

- `ranged_spell.spell_scene` if assigned
- a fallback enemy projectile scene otherwise

So enemies are not limited to melee. They can be given a `SpellData` and fire it as a ranged attack when line of sight is clear.

### Damage resolution flow

A typical spell hit flow looks like this:

1. projectile or effect reaches a target
2. target’s `HitboxComponent` is found
3. `receive_hit` is called with the spell and hit direction
4. damage is calculated using `damage_reduction` and `damage_multiplier`
5. knockback and status effects are applied according to spell flags
6. AOE may expand the effect to nearby bodies
7. projectiles may free themselves depending on piercing behavior

That flow is shared across player spells and enemy spells, which is a good sign that the pipeline is cohesive.

## Progression and gating

### Study gating via the spell tree

The spell tree UI uses course/subject data to decide what the player can learn.

`SpellTreeView` computes:

- subject depth from prerequisites
- lock state from missing prerequisites
- learning cost from difficulty, comprehension, and contained spell count

It then updates lock states when the player learns new spells.

So magic progression is gated by study completion rather than only by currency or level.

### Cost model

The subject cost formula uses:

- a base cost
- a difficulty squared multiplier
- a comprehension multiplier
- a spell count weight

That makes later or deeper subjects more expensive, which is a simple but effective progression curve.

### Spell unlocking from items

Items can also unlock spells directly through `spell_to_unlock`.

That gives items a direct role in the magic pipeline, not just in inventory or economy.

## Magic classification model

Spell data already includes several classification fields:

- `SpellCategory`
- `SpellType`
- `SpellManifest`
- `magis_archetype`
- `magis_comprehension`
- archetype resonance and off-archetype penalty fields

These suggest an intended design where:

- spells have a top-level intent category
- they have a finer type/manifest classification
- they belong to a magis archetype and comprehension level
- casting outside your dominant archetype may be tuned or restricted

Some of those fields may still be partially wired, but they establish the shape of the system: not all spells are equal, and the academic archetype framing is meant to matter.

## Where the pipeline is still incomplete

Based on the current code, a few parts look more established than others:

- spell authoring and loading are clearly in place
- projectile and hitbox resolution are implemented
- incantation mapping exists
- study gating via subjects/courses exists
- enemy spell usage is supported by the combat component

Parts that may still need more work or explicit documentation:

- the full runtime flow from input to spell selection to casting is not fully visible from the current survey
- some spell fields may be intended for systems that are not yet fully built out
- the status effect hook array on `SpellData` is currently described as future-proofing
- the exact incantation input mapping from player controls to `selected_spell` should be documented when the surrounding casting UI/input wiring is finalized

## Summary

The Magis pipeline is already more than a spell list. It is:

- a data-driven spell and study authoring pipeline
- a library loader that indexes spells by id and incantation
- a player learning/equipment layer
- a casting path that can use incantation sequences
- a combat resolution path through projectiles and hitboxes
- a study-gated progression model
- a classification model that supports archetype, comprehension, and spell category

That matches the project’s broader theme: magic is treated as something you learn and apply through structured knowledge, not just a set of isolated abilities.

