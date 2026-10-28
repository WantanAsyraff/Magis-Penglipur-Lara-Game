# Spells

## Purpose, source and placement

[SpellData](../../data/Resources/ilmu/spell.gd) is the reusable definition; [SpellCastingComponent](../../components/spells/spell-casting-component.gd) executes costs/timing and [SpellDelivery](../../components/spells/spell-delivery.gd) interprets delivery. Player spells live directly under `data/magis/spells/` (top-level scan/baker, not arbitrary nested folders). Enemy-only preserved legacy definitions live separately under data/magis/legacy-enemy-spells/. Use [phys-strike.tres](../../data/magis/spells/phys-strike.tres), [thermal-kinetic.tres](../../data/magis/spells/thermal-kinetic.tres) or another actual Physics definition as examples.

## Editor: add a spell without editing Player.gd

1. Right-click data/magis/spells/ → Create New → Resource → SpellData. Save a new kebab-case file. Set a unique explicit spell_id and spell_name; do not copy a released ID/UID. Spell IDs in current content mix hyphens and underscores: preserve existing spelling.
2. Set spell_icon (optional Texture2D), spell_colour, spell_flavour_text and theory_desc for understandable UI. spell_type, spell_manifest, magis_archetype and academic_fields classify the content; they do not replace effects/delivery.
3. Expand spell_incantation: enter lowercase `up`, `down`, `left`, `right`. Check the whole registered/equipped repertoire for an exact duplicate. Empty arrays are not a useful player-cast spell even though SpellValidator does not itself reject emptiness; Spell_Library does.
4. Select an explicit V2 delivery. For an ordinary projectile, configure positive projectile_speed, projectile_range and projectile_size. For an area, set positive aoe_spell_radius. SELF and DIRECT_TARGET do not require projectile fields.
5. Expand effects, add New DamageEffect, set amount; add supported effects in intended order. Explicit nonempty effects **replace** the legacy flag-derived payload, they do not append automatically.
6. Set nonnegative upfront_cost, cast_time, cooldown and recovery_time. Player casts skip post-dispatch recovery; enemies retain recovery_time. Individual spell cooldowns always apply. For channeling set is_channelled, positive channel_duration and mana_per_second. Without live_channel the payload dispatches at channel completion; live_channel is only supported for channelled beam/persistent-area/trap deliveries.
7. Assign relevant FieldData references. Drag the new spell into a subjectData.contained_spells array to make it learnable; field tags alone grant nothing. After purchase, equip it in My Spells. The equipped list builds the player's resolver, not the entire global library.
8. Open tools/bake-spell-manifest.gd in the Script editor and run Ctrl+Shift+X. Review that data/magis/spell-manifest.gd preloads the new top-level path. Open/run tools/validate-spells.gd the same way; resolve errors and review prefix warnings.
9. Play through the subject/unlock/equip route and complete the combo in casting stance. Check accepted-input feedback independently of execution success. Run spell regression, combo, assistant and curriculum tests; add targeted behavior checks rather than changing old expectations blindly.
10. Export a PCK and run the affected scene from it. Save learned/equipped state in an isolated campaign profile and load with a separate process. Do not add custom matching/execution branches to Player.gd for ordinary new content.

## Delivery choices and conditional settings

| Delivery | Required configuration / behavior |
| --- | --- |
| LEGACY | Adapter derives delivery/category and payload only when explicit effects are empty; prefer explicit V2 for new content |
| PROJECTILE | Positive speed/range/size; optional spell_scene must instantiate a SpellEffect-derived projectile. Default uses existing player/enemy projectile scenes; count 1–128 and bounded spread |
| SELF | Executes on caster; an additional positive aoe_spell_radius can also apply an area to other eligible actors |
| DIRECT_TARGET | target_range and valid chosen actor in aim cone; rechecked after preparation |
| AREA_BURST | Positive radius; executes once at source; outward direction used for target effects |
| PERSISTENT_AREA | Positive radius/duration, area_tick_interval ≥ .05; owned, repeatedly ticking area |
| BEAM | Positive target_range/beam_width, duration/interval; one to five beam_angles within ±180 degrees; bounded terrain/optical ray handling |
| TRAP | Positive radius/duration/interval; triggers once when an eligible target enters its detection scan |
| SUMMON | summon_scene must instantiate Node2D. Generic SpellConstruct supports authored solid/follow/reflect flags; a custom creature still needs its own AI/lifetime integration |

`aim_placement` positions the origin along aim by min(target_range, 220). `has_wave_tag` opts spell fields/projectiles into wave cancellation. `affects_projectiles` routes ProjectileFieldEffect through area scanning rather than normal per-hit payload. `construct_solid`, `construct_follow`, `construct_reflect`, `optical_angle` are interpreted by the reusable construct/beam code, not every arbitrary summon scene. Persistent deliveries have a per-caster cap of twelve counted area/construct nodes. The cap does not constitute a universal lifetime manager for every custom summon.

Projectile texture/particles and impact assets provide presentation in the projectile code; inspect [the complete field reference](../reference/resource-reference.md#spelldata) for defaults, exact enum lists, dormant compatibility fields and consumer references. Do not assume cast_sound, resonance or a proc ID has a handler solely because the field is exported.

## Incantation strategies and intentional shared prefixes

Current Player default is **CHAINED**. Strike → Resonate → Shatterwave are three intentional independent spells along a shared prefix. Completing Strike executes it; continuing the valid next direction can execute Resonate, then Shatterwave. A failed shorter spell due to cost/cooldown does not erase the longer path. A legal root restart after a completed prefix follows the current resolver's restart policy. Do not remove prefix warnings by breaking these authored combos.

| Strategy | Exact completion |
| --- | --- |
| CHAINED (default) | Cast immediately; keep longer continuation, permit defined root restart |
| IMMEDIATE | Cast immediately and clear even when longer spells exist |
| CONFIRMATION | Wait for confirm (O/start_incantation when leaving stance) |
| DELAYED | Wait delay_seconds (default .35) when extensions exist; otherwise complete immediately |

Default project bindings are O for stance, I/J/K/L for up/left/down/right, Q for the next locked enemy and P for **clear sequence only**. Player aiming automatically locks the nearest eligible enemy; mouse movement does not aim. See [lock rules and HUD placement](../auto-targeting-and-buff-hud.md). The separate cancel_casting action cancels active/queued casts and starts unbound; assign it in Settings. Saved user keybindings can differ.

My Spells and the available loadout library offer type filters derived from classification, effective delivery and effects. Equipped cards remain visible. See [category rules and snappy chaining](../snappy-combat-and-spell-filters.md).

An exact duplicate combo is ambiguous and invalid catalogue design. A proper prefix is valid and intentional. Resolver re-evaluations do not execute previewed spells. The assistant remains a compact next-direction row; equipped repertoire is separate existing UI.

## Extension boundary and completion checklist

Compose existing [effect types](spell-effects.md) first. A new persistent behavior needs a new effect/component or delivery extension, validators, tests and registration where applicable. Do not add an unhandled string, arbitrary Resource to status_effects, or a new enum value and expect execution automatically.

- [ ] Unique ID, valid directions, meaningful presentation and known field refs.
- [ ] Costs/timing and conditional delivery fields valid; ordered payload tested.
- [ ] Subject acquisition and equipment reachable; manifest baked/reviewed.
- [ ] Correct-key recognition and independent chain behavior preserved.
- [ ] Source and PCK tests plus visual/aim/collision checks; fresh-process save compatibility.

For common failures see [troubleshooting](../reference/troubleshooting.md).

## Native `.tres` composition example

This hypothetical new definition uses the same typed DamageEffect/ApplyStatusEffect schema as thermal-kinetic.tres. It is checked by Godot as a Resource and by SpellValidator. It is not automatically registered or added to the game; follow the Editor/manifest/subject steps above. UIDs are intentionally omitted so a new authored asset does not copy an existing one.

```tres
[gd_resource type="Resource" script_class="SpellData" load_steps=9 format=3]

[ext_resource type="Script" path="res://data/Resources/ilmu/spell.gd" id="spell"]
[ext_resource type="Script" path="res://data/Resources/ilmu/field.gd" id="field_type"]
[ext_resource type="Script" path="res://data/Resources/spell-effects/spell-effect-definition.gd" id="effect_type"]
[ext_resource type="Script" path="res://data/Resources/spell-effects/damage-effect.gd" id="damage"]
[ext_resource type="Script" path="res://data/Resources/spell-effects/apply-status-effect.gd" id="status"]
[ext_resource type="Resource" path="res://data/magis/fields/physics.tres" id="physics"]

[sub_resource type="Resource" id="Damage"]
script = ExtResource("damage")
amount = 10.0

[sub_resource type="Resource" id="Slow"]
script = ExtResource("status")
status = "slow"
duration = 2.0
magnitude = 0.2

[resource]
script = ExtResource("spell")
spell_id = "demo-study-pulse"
spell_name = "Study Pulse"
spell_incantation = Array[String](["up", "up", "right", "down", "left", "down", "up"])
upfront_cost = 10
cast_time = 0.1
recovery_time = 0.15
delivery = 4
aoe_spell_radius = 140.0
effects = Array[ExtResource("effect_type")]([SubResource("Damage"), SubResource("Slow")])
academic_fields = Array[ExtResource("field_type")]([ExtResource("physics")])
```

In this format `delivery = 4` is the current AREA_BURST enum value. Prefer selecting the named value in Inspector; changing enum order would require migration of authored numeric data.
