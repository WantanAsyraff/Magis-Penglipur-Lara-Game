#!/usr/bin/env python3
"""Validate first-party handbook links, source paths, Resource schema coverage and snippets.

No gameplay writes, manifest baking or save access. --write-reference refreshes only
its generated Markdown; --check-gdscript uses GODOT_COMMAND without a shell.
"""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / 'docs/reference/resource-reference.md'
GUIDES = {
 'FieldData':'fields','CourseData':'courses-and-subjects','subjectData':'courses-and-subjects',
 'SpellData':'spells','SpellEffectDefinition':'spell-effects','EnemyData':'enemies',
 'EnemyStatsData':'enemies','EnemyPerceptionData':'enemies','EnemyAIProfile':'enemy-ai',
 'EnemyAIAction':'enemy-ai','EnemyAbilityData':'enemy-abilities','SpawnData':'enemies',
 'BossPhaseData':'bosses','BossAttackData':'bosses','ItemData':'items-and-loot','LootData':'items-and-loot',
 'QuestData':'quests','QuestObjectiveData':'quests','QuestObjectiveGroup':'quests','QuestDatabase':'quests',
 'NPCPresentation':'npcs-and-dialogue','NPCSpawnValidator':'npcs-and-dialogue',
 'NPCSpellcasterData':'additional-systems','SceneData':'worlds-and-scenes','ElevatorFloor':'worlds-and-scenes',
 'TutorialData':'tutorials','TutorialPage':'tutorials',
}
REQUIRED = {
 'FieldData':{'field_id','display_name'},'CourseData':{'course_id','course_name','subjects'},
 'subjectData':{'subject_id','subject_name'},'SpellData':{'spell_id','spell_name','spell_incantation','delivery'},
 'EnemyData':{'enemy_id','faction_id','stats','perception','ai_profile'},'EnemyAIProfile':{'profile_id','actions'},
 'EnemyAIAction':{'action_id','kind'},'EnemyAbilityData':{'ability_id','kind'},'SpawnData':{'enemy_scene'},
 'QuestData':{'quest_id','title','objectives'},'QuestObjectiveData':{'objective_id','type','required_amount'},
 'QuestObjectiveGroup':{'group_id'},'QuestDatabase':{'quests'},'ItemData':{'item_id','item_name','max_stack'},
 'LootData':{'item'},'NPCPresentation':{'npc_id','display_name'},'SceneData':{'scene_id','scene','scene_name'},
 'ElevatorFloor':{'scene_id','floor_name'},'TutorialData':{'pages'},'TutorialPage':{'page_title','page_desc'},
 'NPCSpellcasterData':{'caster_id'},'BossPhaseData':{'enter_at_health_ratio','attacks'},
}
DORMANT = {
 'SpellData':set('resonance_bonus off_archetype_penalty requires_archetype_match status_effects misfire_silence_duration chain_range chain_max_targets chain_damage_falloff equilibrium_bias cast_sound impact_sound'.split()),
 'NPCSpellcasterData':set('race magis_archetype magis_comprehension portrait base_mana_shield low_mana_threshold aggression react_window cast_delay_min cast_delay_max combo_chance counter_chance drops_spell_on_defeat dropped_spell'.split()),
 'QuestData':{'auto_accept_next'},'ItemData':{'ringgit_value','is_sellable','quest_objective_ids'},
 'LootData':{'rarity'},'TutorialData':{'tutorial_title'},
}
PURPOSE = {
 'ringgit_value':'Authored sell/value metadata; no implemented shop transaction consumes it.',
 'is_sellable':'Authored sale eligibility metadata; no implemented shop transaction consumes it.',
 'quest_objective_ids':'Legacy compatibility metadata; current pickups publish actual item IDs/tags.',
 'rarity':'Common/Uncommon/Rare/Epic label metadata; no automatic tier probability mechanic.',
 'race':'Legacy authored species label; not consumed by EnemyDefinitionAdapter.',
 'base_mana_shield':'Legacy authored shield amount; adapter does not implement mana shielding.',
 'low_mana_threshold':'Legacy threshold metadata; utility recovery uses its own current logic.',
 'aggression':'Legacy authored aggression; not mapped into utility weights by the adapter.',
 'react_window':'Legacy reaction timing; no delayed-reaction handler in current adapter.',
 'cast_delay_min':'Legacy minimum delay metadata; not mapped into current ability timings.',
 'cast_delay_max':'Legacy maximum delay metadata; not mapped into current ability timings.',
 'combo_chance':'Legacy probability metadata; no automatic combo handler is installed.',
 'counter_chance':'Legacy probability metadata; no automatic counter handler is installed.',
 'drops_spell_on_defeat':'Legacy toggle; adapter does not install a spell-drop hook.',
 'dropped_spell':'Legacy referenced spell; not granted/dropped by the V2 adapter.',
 'auto_accept_next':'Serialized compatibility flag; next quests still need explicit acceptance.',
 'cast_sound':'Retained AudioStream slot; no current casting playback consumer.',
 'impact_sound':'Retained AudioStream slot; no current impact playback consumer.',
 'resonance_bonus':'Retained bounded resonance tuning; no automatic damage bonus handler.',
 'off_archetype_penalty':'Retained bounded penalty metadata; no automatic penalty handler.',
 'requires_archetype_match':'Retained restriction flag; current casting does not enforce this archetype match.',
 'misfire_silence_duration':'Retained tuning; current targeted-decast miss path does not implement this silence.',
 'chain_range':'Retained legacy tether/chain tuning; ChainEffect uses its own radius.',
 'chain_max_targets':'Retained legacy tuning; ChainEffect uses its own bounded hops.',
 'chain_damage_falloff':'Retained legacy tuning; ChainEffect uses its implemented .75 factor.',
 'equilibrium_bias':'Retained legacy tether tuning; no equilibrium-drain handler.',
 'status_effects':'Retained arbitrary Resource hook; actual statuses use typed effects/ActiveEffectManager.',
 'tutorial_title':'Authored tutorial metadata; current panel displays each page_title instead.',
 'hp_regen_rate':'Legacy HP regeneration mapped to EnemyStatsData.health_regen.',
 'base_defense':'Legacy flat mitigation mapped to EnemyStatsData.defense.',
 'max_hp':'Legacy initial HP mapped to EnemyStatsData.max_health.',
 'mana_regen_rate':'Legacy mana regeneration mapped to EnemyStatsData.mana_regen.',
 'mana_regen_delay':'Legacy delay mapped to EnemyStatsData.regen_delay.',
 'spell_pool':'Legacy spell references converted into authorized EnemyAbilityData entries.',
 'preferred_spell_types':'Legacy SpellType names that increase converted ability preference weight.',
 'forbidden_spell_types':'Legacy SpellType names omitted from converted loadout.',
 'too_close_threshold':'Legacy retreat range mapped to copied cautious-spellcaster profile.',
 'stun_resistance':'Legacy duration resistance mapped to stun key in EnemyStatsData.',
 'dot_resistance':'Legacy duration resistance mapped to dot key in EnemyStatsData.',
 'impairment_resistance':'Legacy duration resistance mapped to slow key in EnemyStatsData.',

 'academic_fields':'Referenced FieldData academic identities; not delivery/automatic unlock logic.',
 'related_field_ids':'Academic relationship metadata; no automatic prerequisite/bonus resolution.',
 'field_id':'Stable academic key, including comprehension dictionary matching.',
 'display_name':'Human-readable label; NPC presentation also uses fallback resolution.',
 'description':'Authored explanatory text, not a gameplay handler.',
 'prerequisites':'Completed subject IDs; course and subject purchase gates.',
 'contained_spells':'Spells learned after a successful once-only subject purchase; equipment is separate.',
 'comprehension_requirements':'Field StringName → minimum rank; actual rank must be awarded deliberately.',
 'difficulty_level':'Inspector 1–5; subject difficulty contributes quadratically to purchase cost.',
 'magis_comprehension':'Classification label; subject value selects the purchase cost multiplier.',
 'magis_archetype':'Authored Magis classification; not a player class or automatic resonance mechanic.',
 'subject_archetype':'Academic category selected from the schema enum.',
 'course_archetype':'Authored course classification/presentation label.',
 'field_of_study':'Subject academic context displayed by study UI.',
 'theoretical_foundation':'Subject academic explanation for study presentation.',
 'casters_notes':'Subject practical casting notes for study presentation.',
 'subjects':'Ordered subjectData references rendered by the assigned course view.',
 'course_description':'Authored course description.',
 'spell_id':'Stable library/authorization/save identifier; exact spelling is significant.',
 'spell_incantation':'Lowercase direction sequence; exact duplicates invalid, proper prefixes supported.',
 'spell_scene':'Optional projectile PackedScene; must instantiate SpellEffect; default projectile if empty.',
 'spell_category':'Legacy payload/delivery adapter and decast target policy; explicit effects take precedence.',
 'spell_type':'Authored classification; legacy spellcaster preferences consume this enum.',
 'spell_manifest':'Authored classification metadata, not the generated spell registry.',
 'spell_colour':'Spell/projectile/field feedback tint.',
 'spell_icon':'Texture shown in spell study/equipment/repertoire UI.',
 'spell_flavour_text':'Authored description used by spell presentation.',
 'theory_desc':'Authored spell theory explanation.',
 'upfront_cost':'Mana paid when a cast starts; cancellation rules belong to casting service.',
 'mana_per_second':'Mana consumed per active channel second.',
 'cast_time':'Preparation time, modified by supported buff_cast_speed.',
 'is_channelled':'Enables positive-duration channel stage.',
 'channel_duration':'Channel lifetime; ordinary channel dispatches at end, live_channel starts delivery earlier.',
 'cooldown':'Seconds until reuse; ordinary ability and spell cooldowns both apply.',
 'recovery_time':'Post-execution casting recovery seconds.',
 'target_range':'Direct target/beam reach; also contributes to aim placement and enemy range setup.',
 'delivery':'Select explicit supported delivery or use LEGACY adapter.',
 'effects':'Ordered typed payload; nonempty SpellData array replaces legacy-derived effects.',
 'targeting':'ENEMIES/ALLIES/ANY relation policy; SELF delivery executes on caster.',
 'aoe_spell_radius':'Actor area radius; some constructs use it for interception.',
 'area_duration':'Persistent field or reusable construct lifetime.',
 'area_tick_interval':'Persistent scan/tick interval, at least .05 for validated persistent delivery.',
 'beam_width':'Beam projection/geometry width, must be positive for BEAM.',
 'beam_angles':'One to five output beam angles, finite within ±180 degrees.',
 'optical_angle':'Optical-interface angle interpreted by compatible construct/beam code.',
 'construct_solid':'Reusable SpellConstruct creates a solid 150×16 shape, after placement check.',
 'construct_follow':'Reusable construct follows caster; arbitrary summons do not gain this automatically.',
 'construct_reflect':'Reusable construct redirects hostile intercepted projectiles rather than cancelling.',
 'summon_scene':'Required Node2D scene for SUMMON delivery; custom behavior needs compatible implementation.',
 'aim_placement':'Offset cast source along aim by min(target_range,220).',
 'live_channel':'Only validated for channelled BEAM/PERSISTENT_AREA/TRAP; cancels owned live delivery.',
 'has_wave_tag':'Opt-in wave identity for projectile/area cancellation.',
 'affects_projectiles':'Route projectile-field payload through area/projectile scanning.',
 'projectile_texture':'Projectile sprite texture when assigned.',
 'projectile_particles':'Optional projectile particle child scene.',
 'impact_particles':'Optional presentation spawned on impact.',
 'projectile_count':'Number of projectiles, 1–128.',
 'projectile_spread':'Spread angle, finite within ±360 degrees.',
 'projectile_speed':'Positive projectile movement speed.',
 'projectile_size':'Positive projectile size/scale configuration.',
 'projectile_range':'Positive maximum travel range.',
 'projectile_damage':'Legacy DamageEffect amount when no explicit effect payload replaces it.',
 'piercing':'Projectile can continue after target contact while preserving per-target hit control.',
 'explosive':'Projectile impact explosion configuration; see projectile consumer for actual radius behavior.',
 'is_self_cast':'Legacy delivery override to SELF.',
 'heal_amount':'Legacy immediate healing amount.',
 'heal_over_time':'Legacy switch from immediate heal to hot payload.',
 'hot_tick_heal':'Legacy healing amount per periodic tick.',
 'hot_tick_interval':'Legacy hot interval.',
 'hot_duration':'Legacy hot duration.',
 'buff_type':'Legacy enum mapped to one supported buff_stat key.',
 'buff_magnitude':'Legacy ModifyStatEffect amount; stat consumers determine units.',
 'buff_duration':'Legacy buff duration.',
 'is_stackable':'Legacy buff STACK versus REFRESH policy.',
 'max_stacks':'Maximum independent stacks; configured policies and manager cap apply.',
 'on_hit_proc_id':'Stored proc metadata; no generic on-hit proc dispatcher is implemented.',
 'decast_mode':'Legacy SELF versus area/targeted decast routing.',
 'decast_radius':'Decast area radius when category is DECAST.',
 'purge_enemy_buffs':'Enable hostile buff clear in legacy decast payload/targeting.',
 'purge_debuffs':'Enable allied debuff clear in legacy decast payload/targeting.',
 'stunnable':'Legacy enables stun payload (name describes application, not receiver immunity).',
 'stun_dur':'Legacy stun duration.',
 'dot':'Legacy enables damage-over-time payload.',
 'dot_damage':'Legacy periodic damage per tick.',
 'dot_interval':'Legacy periodic damage interval.',
 'dot_duration':'Legacy damage-over-time duration.',
 'applies_slow':'Legacy enables slow payload.',
 'slow_factor':'Legacy slow fraction clamped/validated to 0–1.',
 'slow_duration':'Legacy slow duration.',
 'applies_mana_drain':'Legacy enables periodic mana drain payload.',
 'mana_drain_amount':'Legacy periodic mana drained per tick.',
 'mana_drain_duration':'Legacy drain duration.',
 'applies_silence':'Legacy enables silence payload.',
 'silence_duration':'Legacy silence duration.',
 'amount':'Payload magnitude; exact stat/damage/heal/chain semantics are in the effect guide.',
 'duration':'Effect/trigger lifetime in seconds; validate per subclass.',
 'tick_interval':'Periodic interval; effect validators require at least .05 seconds.',
 'status':'Existing handler/marker key; not a new mechanic implementation by itself.',
 'magnitude':'Status amount/factor supplied to the existing handler.',
 'stacking':'REFRESH/REPLACE/STACK/IGNORE; manager counts independent entries.',
 'stat':'One of speed/damage/mana_regen/defense/cast_speed/dash_charges.',
 'force':'Knockback impulse magnitude, finite nonnegative.',
 'distance':'Swept teleport distance along cast direction.',
 'scene':'SceneData destination or SpawnEntityEffect Node2D template; parent-specific contract.',
 'offset':'Finite spawn offset relative to target.',
 'children':'Nested ordered effects under the same execution/context contract.',
 'required_status':'Required status key on target.',
 'minimum_stacks':'Count required by ConditionalEffect; author positive meaningful values.',
 'consume':'ConditionalEffect removes all matching-key stacks before children.',
 'capability':'Optional metadata presence gate, not a newly installed ability.',
 'radius':'Effect search/field radius; finite constraints depend on subclass.',
 'hops':'Bounded extra chain hops, 1–8.',
 'preferred_status':'Bias chain target distance score for this status; not a mandatory filter.',
 'hits':'Trigger damage-event activation count, 1–6.',
 'mode':'Subclass enum selects existing behavior; adding an enum alone does not implement it.',
 'strength':'Vector/projectile field magnitude; DAMP/SLOW have specialized fractional semantics.',
 'respect_teams':'Gate category clears by ally/hostile; named status removal is independent.',
 'remove_buffs':'Clear beneficial entries, respecting team option if requested.',
 'remove_debuffs':'Clear negative entries, respecting team option if requested.',
 'enemy_id':'Explicit stable enemy type identity; compatibility getter may fall back to quest ID or filename.',
 'quest_enemy_id':'Kill observer identity; match registered enemy/objective ID for quests.',
 'enemy_name':'Visible enemy name.',
 'enemy_category':'Authored classification metadata; not a controller dispatcher.',
 'faction_id':'Team identity for targeting and friendly-fire rules.',
 'visual_scene':'Optional appearance-only Node2D; preserve shared gameplay shell.',
 'stats':'Required EnemyStatsData reference; live HP/mana live in component state.',
 'perception':'Required EnemyPerceptionData reference.',
 'ai_profile':'Required EnemyAIProfile reference.',
 'abilities':'Authorized EnemyAbilityData loadout; not the global spell library.',
 'cooldown_multiplier':'Positive scale on ability cooldowns.',
 'loot':'Independent LootData entries consumed once per authoritative death.',
 'experience_reward':'Nonnegative XP on ordinary enemy death; not a quest reward amount.',
 'death_delay':'Bounded 0–30 seconds before cleanup.',
 'enemy_tags':'Tags published on credited enemy death events.',
 'max_health':'Positive starting/max HP; runtime HP is not written into the Resource.',
 'max_mana':'Mana capacity/initial value; 0 means no mana pool for ordinary enemy.',
 'health_regen':'Health per second after configured regen delay.',
 'mana_regen':'Mana per second; enemy stat service also considers drain and regen delay.',
 'regen_delay':'Post-damage/mana-spend delay before passive regeneration.',
 'move_speed':'Phase/enemy move/patrol speed.',
 'chase_speed':'Phase/enemy chase speed; boss dash scales this.',
 'defense':'Flat incoming damage reduction; negative phase override preserves boss base.',
 'incoming_multiplier':'Incoming damage multiplier; negative phase override preserves boss base.',
 'outgoing_multiplier':'Outgoing damage metadata consumed by cast/combat context.',
 'knockback_resistance':'0–1 fractional reduction of knockback.',
 'status_resistances':'Status key → 0–1 duration resistance; 1 refuses application through apply_status.',
 'detection_range':'Perception scan range, positive ≤10000.',
 'sight_memory':'Seconds remembering a lost visible target.',
 'scan_interval':'Perception scan cadence, at least .05.',
 'max_candidates':'Candidate bound 1–64.',
 'terrain_mask':'Perception occlusion bits; combat LOS has its own fixed terrain mask.',
 'target_groups':'SceneTree groups searched for eligible targets.',
 'relations':'Other faction → -1 hostile / 0 neutral / 1 allied; same faction allied.',
 'threat_decay':'Decay of accumulated threat per second.',
 'profile_id':'Stable profile identifier; direct parent reference supplies discovery.',
 'actions':'Nonempty unique-ID utility actions.',
 'decision_interval':'At least .05 seconds between eligible AI decisions.',
 'commitment':'Duration of switching resistance while current action stays eligible.',
 'switch_margin':'Relative score improvement needed during commitment.',
 'preferred_range':'Desired engagement range, adjusted for pure-melee reach.',
 'retreat_range':'Close-threat distance used by retreat/defend eligibility.',
 'range_tolerance':'Dead band around preferred engagement distance.',
 'flee_health_ratio':'0–1 maximum health ratio for FLEE eligibility.',
 'patrol_range':'Local patrol distance from origin.',
 'wall_jump_velocity':'Nonpositive vertical wall-jump impulse.',
 'action_id':'Unique action ID; fallback derives from kind but explicit IDs avoid collisions.',
 'kind':'Exact enum selects supported action/ability/attack implementation.',
 'utility':'Base eligible action score.',
 'max_health_ratio':'Upper HP fraction threshold for action eligibility, 0–1.',
 'max_mana_ratio':'Upper mana fraction threshold for action eligibility, 0–1.',
 'low_health_weight':'Score factor growing as health falls.',
 'low_mana_weight':'Score factor growing as mana falls.',
 'threat_weight':'Score factor for capped threat consideration.',
 'ability_id':'Loadout identity / optional action filter; not implicit authorization.',
 'role':'OFFENSE/DEFENSE/HEAL/SUMMON action compatibility.',
 'spell':'Required SpellData for SPELL ability.',
 'min_range':'Minimum target root-to-root distance for nonself ability.',
 'max_range':'Maximum target root-to-root distance for nonself ability.',
 'requires_los':'Require combat line of sight to nonself target.',
 'windup':'Attack release delay; ability spell can also have its own cast_time.',
 'recovery':'Ordinary enemy ability recovery seconds.',
 'weight':'Boss pool random weight; ordinary ability highest-ready preference.',
 'enemy_scene':'Required Enemy-derived PackedScene for spawner entry.',
 'enemy_data':'Optional SpawnData override, applied before Enemy._ready.',
 'spawn_weight':'Positive relative spawner selection weight; zero entries are skipped.',
 'phase_name':'Visible boss phase label.',
 'enter_at_health_ratio':'Boss phase entry fraction, order descending with phase one at 1.',
 'attacks':'Nonempty reachable BossAttackData pool for phase.',
 'invincible_on_transition':'Enable temporary boss invulnerability during transition.',
 'transition_invincible_duration':'Invulnerability duration; contributes to max transition wait.',
 'transition_duration':'Phase transition wait, combined with invulnerability wait.',
 'phase_colour':'Presentation tint consumed by compatible guardian visual.',
 'transition_animation':'Existing sprite animation name or empty fallback.',
 'attack_name':'Visible boss telegraph label.',
 'melee_damage':'Slam/dash damage before shared mitigation.',
 'melee_arc_degrees':'Slam arc, Inspector 1–360 degrees.',
 'telegraph_colour':'Boss warning tint.',
 'melee_range':'Slam radius / dash hit-radius base; see boss geometry table.',
 'dash_speed_multiplier':'Multiplier of current phase chase_speed.',
 'dash_duration':'Dash travel interval, stopped by world collision.',
 'ranged_spell':'Boss burst spell template; duplicated for boss windup/per-shot cost.',
 'burst_count':'Boss shots, runtime clamp 1–32.',
 'burst_interval':'Time between burst shots, runtime minimum .01.',
 'burst_spread':'Boss burst angular spread.',
 'aoe_radius':'Boss warning circle and damage-query radius.',
 'aoe_damage':'Boss AoE damage before shared mitigation.',
 'aoe_knockback':'Boss AoE outward knockback magnitude.',
 'aoe_warning_duration':'Warning wait for AoE; not attack.windup.',
 'minion_scene':'Node2D scene instantiated by boss SUMMON.',
 'minion_count':'Desired minions, bounded by twelve owned minions.',
 'spawn_radius':'Radial minion placement offset; no automatic placement safety solver.',
 'item_id':'Stable registry/inventory/save/event identifier.',
 'item_name':'Visible inventory/loot/recipe label.',
 'item_icon':'Inventory/loot/quest presentation texture.',
 'item_type':'Authored category enum, not a generic gear/use implementation.',
 'is_stackable':'False limits effective stack to one.',
 'max_stack':'Positive per-ID stack capacity when stackable.',
 'health_restore':'Health restored per accepted pickup quantity, not on arbitrary inventory additions.',
 'mana_restore':'Mana restored per accepted pickup quantity.',
 'exp_reward':'XP per accepted pickup, or legacy enemy death XP through adapter (class dependent).',
 'spell_to_unlock':'Spell learned through pickup hook; no automatic equipment.',
 'tags':'Semantic event/filter tags; not automatic mechanics.',
 'item':'Required LootData item reference.',
 'drop_chance':'Independent death roll probability 0–1; fixed quest rewards do not roll it.',
 'min_quantity':'Inclusive drop lower bound; equal min/max required for quest rewards.',
 'max_quantity':'Inclusive upper bound, ≥min and ≤9999; fixed rewards require equal bounds.',
 'extra_drops':'Explicit bundled item refs sharing parent roll and quantity bounds.',
 'rarity_color':'Tint applied to physical loot particles.',
 'quest_id':'Stable quest registry/instance/reward-claim identity.',
 'title':'Quest visible title, required by registry.',
 'type':'Quest/objective enum; objective selects evaluator behavior, quest type is classification.',
 'faculty':'Quest/NPC offering faculty enum; does not auto-register a database.',
 'despawn_after_seconds':'Available offer/NPC-instance despawn timer setting, separate from active expiry.',
 'objectives':'Nonempty QuestObjectiveData array with unique local IDs.',
 'reward_xp':'Nonnegative XP in the centralized once-only claim transaction.',
 'reward_currency':'Nonnegative currency in the centralized claim transaction.',
 'reward_items':'Fixed unbundled LootData rewards using registered item identities.',
 'prerequisite_quest_ids':'Registered completed quest IDs required before offering/acceptance.',
 'next_quest_id':'Registered next quest offered for explicit acceptance after commit.',
 'region_id':'Catalogue/board region filter.',
 'pool_id':'Authored quest pool metadata; no new automatic pool picker by itself.',
 'repeatable':'Allow new completed-quest instances subject to per-instance claim guards.',
 'hand_in_npc_id':'Required giver ID; empty uses assigned NPC.',
 'expires_after_seconds':'Optional active quest wall-clock expiry; 0 disables it.',
 'objective_groups':'ALL/ANY group definitions for matching objective group_id.',
 'reward_spells':'Registered spells learned by the existing reward transaction.',
 'reward_flags':'Boolean durable world flags set by claim.',
 'dialogue_offer':'Authored offer text, subject to NPC presentation override/fallback policy.',
 'dialogue_incomplete':'Text for active incomplete objectives.',
 'dialogue_complete':'Text after successful hand-in.',
 'dialogue_accepted':'Quest-specific explicit acceptance reaction.',
 'dialogue_declined':'Quest-specific explicit decline reaction.',
 'objective_id':'Stable progress key unique within one quest.',
 'is_optional':'Optional objective/group excluded from mandatory completion.',
 'target_id':'Exact event target identity, unioned with target_ids.',
 'target_ids':'Explicit union of alternative target identities.',
 'target_tags':'Any matching event tag can match cumulative event objectives.',
 'required_amount':'Positive objective bound, up to 1000000 in registry validation.',
 'requires_objectives':'Objective prerequisite IDs; cycles rejected.',
 'collection_mode':'CUMULATIVE acquisition vs CURRENT_HELD vs consuming DELIVERY.',
 'match_metadata':'All configured event metadata key/value constraints must match.',
 'group_id':'Objective group identity / membership reference.',
 'policy':'ALL or ANY required group members.',
 'minimum_completed':'Positive ANY requirement; registry checks satisfiability.',
 'quests':'QuestData references; only registry-loaded databases become authoritative catalogue.',
 'npc_id':'Stable giver/contact/event identity; distinct from dialogue portrait ID.',
 'portrait':'Optional fallback portrait texture.',
 'dialogic_character':'Optional compatible Dialogic Resource exposing portrait/default_portrait data.',
 'dialogue_identity':'Portrait/timeline selector distinct from NPC ID when needed.',
 'offer_dialogue':'Presentation-level offer text override.',
 'accepted':'Default explicit acceptance reaction.',
 'declined':'Default explicit decline reaction.',
 'reoffer_cooldown':'Temporary reoffer delay after decline; no save of live offer tokens.',
 'scene_id':'Stable trusted SceneData key, or registered destination key on ElevatorFloor.',
 'scene_name':'Location display label.',
 'default_spawn_marker':'Elevator fallback marker; ordinary ZoneRoot searches PlayerSpawn itself.',
 'floor_name':'Visible elevator floor button label.',
 'spawn_marker_override':'Selected arrival marker override.',
 'locked':'Grey/disable elevator entry; no automatic academic unlock handler.',
 'locked_hint':'Elevator locked-button explanation.',
 'pages':'Ordered non-null TutorialPage references.',
 'page_title':'Visible current tutorial page title.',
 'page_desc':'Multiline current tutorial page content.',
 'page_image':'Optional tutorial image; empty hides image widget.',
 'allowed_region':'NPC placement bounds relative to spawner.',
 'body_size':'NPC placement footprint in world units.',
 'obstacle_margin':'Extra obstacle-clearance margin.',
 'interaction_clearance':'Required adjacent full-height player approach lane width.',
 'minimum_separation':'Minimum spacing from other placed NPC centers.',
 'max_attempts':'Number of additional random placement candidates.',
 'solid_mask':'Terrain bits for NPC ground/obstacle checks.',
 'ground_search':'Maximum downward ground ray distance.',
 'max_step':'Maximum accepted walking/support height difference.',
 'fallback_enabled':'Append fallback feet candidate; safety checks still apply.',
 'fallback_feet':'Local feet position used only when fallback enabled.',
}

def sources():
    paths=[]
    for folder in ('data','components','autoloads','scenes','system'):
        paths.extend(sorted((ROOT/folder).rglob('*.gd')))
    return {p:p.read_text() for p in paths}

def schemas(texts):
    classes={}
    for p,text in texts.items():
        name=re.search(r'^class_name\s+(\w+)',text,re.M)
        base=re.search(r'^(?:class_name\s+\w+\s+)?extends\s+(\w+)',text,re.M)
        if name and base: classes[name[1]]=(p,text,base[1])
    found={}; changed=True
    while changed:
        changed=False
        for name,(p,text,base) in classes.items():
            if name not in found and (base=='Resource' or base in found):
                found[name]=(p,text,base); changed=True
    return found

def exports(text):
    result=[]; lines=text.splitlines(); i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line.startswith('@export') or line.startswith(('@export_group','@export_subgroup','@export_category')):
            i+=1; continue
        hint=line; start=i+1
        while '(' in hint and hint.count('(')>hint.count(')') and i+1<len(lines):
            i+=1; hint+=' '+lines[i].strip()
        declaration=re.search(r'\bvar\s+(\w+)\s*(.*)',hint)
        if not declaration:
            j=i+1
            while j<len(lines) and (not lines[j].strip() or lines[j].strip().startswith('#')): j+=1
            if j<len(lines): declaration=re.match(r'var\s+(\w+)\s*(.*)',lines[j].strip())
        if not declaration: raise ValueError('Unparsed exported property: '+hint)
        name,rest=declaration.groups(); rest=rest.split(' #')[0].strip().rstrip(':')
        annotation=hint.split(' var ')[0] if ' var ' in hint else hint
        comments=[]; k=start-2
        while k>=0 and lines[k].strip().startswith('##'):
            comments.insert(0,lines[k].strip().lstrip('#').strip()); k-=1
        result.append((name,rest,annotation,' '.join(comments)))
        i+=1
    return result

CONSUMERS = {
 'FieldData':['components/spells/spell-validator.gd','autoloads/player-data.gd'],
 'CourseData':['scenes/spell-tree/spell-tree.gd','autoloads/player-data.gd','components/save/game-save-schema.gd'],
 'subjectData':['autoloads/player-data.gd','scenes/spell-tree/subject-panel.gd','components/save/game-save-schema.gd'],
 'SpellData':['components/spells/spell-casting-component.gd','components/spells/spell-delivery.gd','components/spells/legacy-spell-adapter.gd','components/projectiles/magis-projectile.gd','components/spells/spell-area-delivery.gd','components/spells/spell-construct.gd'],
 'EnemyData':['components/NPCs/enemies/enemy.gd','components/quests/quest-registry.gd'],
 'EnemyStatsData':['components/NPCs/enemies/enemy-stats-component.gd'],
 'EnemyPerceptionData':['components/NPCs/enemies/enemy-detection.gd'],
 'EnemyAIProfile':['components/NPCs/enemies/enemy-ai-controller.gd','components/NPCs/enemies/enemy-movement-component.gd'],
 'EnemyAIAction':['components/NPCs/enemies/enemy-ai-controller.gd'],
 'EnemyAbilityData':['components/NPCs/enemies/enemy-combat.gd','components/NPCs/enemies/enemy-ai-controller.gd'],
 'SpawnData':['components/NPCs/enemies/spawner/enemy-spawner.gd'],
 'NPCSpellcasterData':['components/NPCs/enemies/enemy-definition-adapter.gd'],
 'BossPhaseData':['components/NPCs/enemies/boss/boss.gd','components/NPCs/enemies/boss/resonance-guardian-visual.gd'],
 'BossAttackData':['components/NPCs/enemies/boss/boss.gd','components/NPCs/enemies/boss/boss-telegraph.gd'],
 'ItemData':['autoloads/inventory-manager.gd','scenes/crafting-room/crafting-ui.gd','components/quests/quest-registry.gd'],
 'LootData':['components/NPCs/enemies/enemy-loot-component.gd','components/loot/dropped-item/dropped-item.gd','components/quests/quest-reward-service.gd'],
 'QuestData':['autoloads/quest-manager.gd','components/quests/quest-reward-service.gd','components/quest-manager/quest-instance.gd','components/quests/quest-registry.gd'],
 'QuestObjectiveData':['components/quests/quest-objective-evaluator.gd','components/quest-manager/quest-instance.gd','components/quests/quest-registry.gd'],
 'QuestObjectiveGroup':['components/quest-manager/quest-instance.gd','components/quests/quest-registry.gd'],
 'QuestDatabase':['components/quests/quest-registry.gd','components/quests/quest-board.gd'],
 'NPCPresentation':['components/NPCs/quest-npc-component.gd','autoloads/quest-manager.gd'],
 'NPCSpawnValidator':['components/NPCs/enemies/spawner/npc-quest-spawner.gd'],
 'SceneData':['autoloads/scene-registry.gd','data/worlds/zone-root.gd','components/elevator/elevator-portal.gd'],
 'ElevatorFloor':['components/elevator/elevator-portal.gd','scenes/ui/elevator-ui/elevator-ui.gd'],
 'TutorialData':['components/NPCs/tutorial-component.gd','components/panels/tutorials/tutorial-panel.gd'],
 'TutorialPage':['components/panels/tutorials/tutorial-panel.gd'],
}

def inferred_type(default):
    if default.startswith(('"',"'")): return 'String (inferred)'
    if default in ['true','false']: return 'bool (inferred)'
    if re.fullmatch(r'-?\d+',default): return 'int (inferred)'
    if re.fullmatch(r'-?\d*\.\d+',default): return 'float (inferred)'
    if default.startswith('Rect2'): return 'Rect2 (inferred)'
    if default.startswith('Vector2'): return 'Vector2 (inferred)'
    return 'inferred from default'

def generate_reference(found,texts):
    out=['# Resource property reference','',
      'Generated from every first-party Resource-derived schema by `python3 tools/validate-docs.py --write-reference`. Do not hand-edit generated field tables: update schema notes/tooling and regenerate. Runtime behavior/required playable combinations are explained in each linked canonical guide. Inspector hints are not always runtime validators. “Required” means authoring contract, including meaningful presentation; “Conditional/optional” may become mandatory for a selected delivery/mode. A schema default alone does not establish gameplay completeness.','',
      'Each table gives the exact declaration/default and Inspector hint, purpose, registration/persistence implications and source consumers. Consumer links are lexical source evidence to inspect, **not proof every assignment affects execution**. Explicit dormant/legacy notes override apparent comment or validator-only references. Unassigned typed fields use Godot type defaults (empty string/zero/null/empty collection as applicable). Parent references retain nested Resources in export; ID-bearing definitions need the registration matrix.','',
      '[Registration matrix](content-registration-matrix.md) · [Authoring index](../authoring/README.md) · [Content evolution](../architecture/save-load-architecture.md)','']
    for name,(p,text,base) in sorted(found.items()):
        guide=GUIDES.get(name,'spell-effects' if base=='SpellEffectDefinition' else None)
        if not guide: raise ValueError('Resource without a guide: '+name)
        rel=p.relative_to(ROOT).as_posix(); props=exports(text)
        out.extend([f'## {name}','',f'Source: [{rel}](../../{rel}). Base: `{base}`. [Canonical authoring and validation](../authoring/{guide}.md).',''])
        enums=re.findall(r'enum\s+(\w+)\s*\{([^}]+)\}',text,re.S)
        for enum,values in enums:
            clean=re.sub(r'#.*','',values)
            out.append('Enum `'+enum+'`: '+', '.join('`'+x.strip()+'`' for x in clean.split(',') if x.strip())+'.')
        if enums: out.append('')
        out.extend(['| Property | Type | Purpose | Required? | Default | Validation / notes | Consumer/source evidence |','| --- | --- | --- | --- | --- | --- | --- |'])
        for prop,rest,hint,comment in props:
            status='Required' if prop in REQUIRED.get(name,set()) else 'Conditional/optional'
            purpose=PURPOSE.get(prop,comment or ('Authored '+prop.replace('_',' ')+'; see canonical guide and consumers for its supported use.'))
            if prop.startswith('ingredient_'): purpose='Recipe input ItemData reference; null means unused input slot.'
            if re.fullmatch(r'qty_[123]',prop): purpose='Recipe input positive quantity; 0 for unused null ingredient.'
            if prop.endswith('_name') and prop not in PURPOSE: purpose='Human-readable authored name for this definition.'
            if prop.endswith('_id') and prop not in PURPOSE: purpose='Stable authored identifier; match parent/registry/event references exactly.'
            if prop in DORMANT.get(name,set()): purpose='**Metadata/legacy or unused in current execution.** '+purpose
            if name=='NPCSpellcasterData' and prop not in DORMANT[name]: purpose='Legacy adapter input (when mapped); inspect EnemyDefinitionAdapter. '+purpose
            uses=[]
            pattern=re.compile(r'\.'+re.escape(prop)+r'\b|["\']'+re.escape(prop)+r'["\']')
            if base=='SpellEffectDefinition': uses.append(f'[validate / execute](../../{rel})')
            if prop not in DORMANT.get(name,set()):
                for candidate in CONSUMERS.get(name,[]):
                    other=ROOT/candidate
                    if other in texts and pattern.search(texts[other]):
                        uses.append(f'[{other.stem}](../../{candidate})')
                        if len(uses)==2: break
            if not uses: uses=[f'[Schema / methods](../../{rel})']
            clean=lambda s:s.replace('|','\\|').replace('`','\\`')
            declaration=rest
            if declaration.startswith(':='):
                default=declaration[2:].strip(); dtype=inferred_type(default)
            elif declaration.startswith(':'):
                bits=declaration[1:].split('=',1); dtype=bits[0].strip()
                default=bits[1].strip() if len(bits)>1 else 'Godot type default'
            elif declaration.startswith('='):
                default=declaration[1:].strip(); dtype=inferred_type(default)
            else:
                dtype='Variant'; default='Godot type default'
            if name=='NPCSpellcasterData' and prop in ['magis_archetype','magis_comprehension']:
                purpose='**Legacy metadata, unused by the adapter.** Authored caster identity/classification label.'
            out.append(f'| `{prop}` | `{clean(dtype)}` | {purpose} | {status} | `{clean(default)}` | `{clean(hint)}`; see guide for runtime constraints. | '+', '.join(uses)+' |')
        if not props: out.append('| — | — | No exported fields; runtime contract in methods. | — | — | — | [Source](../../'+rel+') |')
        out.append('')
    out.extend(['## Persistence and runtime values','',
      'Stable field/subject/spell/item/quest/scene/giver identities and dictionary/event targets are documented in the [identifier guide](identifiers-and-conventions.md). Resource files contain authored defaults, not live HP, cast queues, objective progress or cooldowns. Save V1 stores its explicit supported runtime state and resolves registered IDs; it does not dump these Resource objects into JSON. A declaration with no behavioral consumer must not be advertised as an implemented mechanic.',''])
    return '\n'.join(out)

def anchor_names(text):
    anchors=set(); seen={}
    for heading in re.findall(r'^#{1,6}\s+(.+?)\s*#*$',text,re.M):
        slug=re.sub(r'[^\w\- ]','',re.sub(r'[`*_]','',heading).lower()).replace(' ','-')
        n=seen.get(slug,0); seen[slug]=n+1
        anchors.add(slug+('-'+str(n) if n else ''))
    anchors.update(re.findall(r'(?:id|name)=["\']([^"\']+)',text))
    return anchors

def validate_links(documents):
    issues=[]; checked=0
    for p in documents:
        text=p.read_text()
        prose=re.sub(r'```.*?```','',text,flags=re.S)
        prose=re.sub(r'`[^`]*`','',prose)
        for raw in re.findall(r'!?\[[^\]]*\]\(([^\n]+?)\)',prose):
            target=raw.strip().strip('<>')
            if re.match(r'(https?://|mailto:|plugin:|app:)',target): continue
            target=unquote(target)
            path,_,anchor=target.partition('#')
            dest=(p.parent/path).resolve() if path else p
            checked+=1
            if not dest.exists(): issues.append(f'{p.relative_to(ROOT)}: missing linked target {raw}')
            elif anchor and dest.suffix=='.md' and anchor not in anchor_names(dest.read_text()):
                issues.append(f'{p.relative_to(ROOT)}: missing Markdown anchor {raw}')
        # res:// references in inline code/snippets must be concrete files (wildcards are not assertions).
        for path in re.findall(r'res://([\w./()\-]+\.(?:gd|tscn|tres|py))',text):
            checked+=1
            if not (ROOT/path).is_file(): issues.append(f'{p.relative_to(ROOT)}: missing res://{path}')
    return checked,issues

def run_doc_scene(work,source,marker):
    """Load code in the ordinary project scene context so autoload names exist."""
    command=shlex.split(os.environ.get('GODOT_COMMAND','godot'))
    helper=work/'check.gd'; helper.write_text(source)
    resource_path='res://'+helper.relative_to(ROOT).as_posix()
    scene=work/'check.tscn'
    scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="'+resource_path+'" id="1"]\n[node name="DocumentationCheck" type="Node"]\nscript = ExtResource("1")\n')
    proc=subprocess.run(command+['--headless','--path',str(ROOT),str(scene),'--','--quest-test-mode'],capture_output=True,text=True,timeout=60)
    output=proc.stdout+proc.stderr
    result=re.search(re.escape(marker)+r'.*',output)
    failures=[line for line in output.splitlines() if 'SCRIPT ERROR:' in line or ('ERROR:' in line and 'resources still in use at exit' not in line)]
    if proc.returncode or not result or failures: return ['Godot documentation scene failed: '+output]
    print(result[0])
    if 'resources still in use at exit' in output: print('NOTE: existing engine resource shutdown diagnostic remains.')
    return []

def check_snippets(documents):
    import json
    count=0
    with tempfile.TemporaryDirectory(prefix='handbook-scripts-',dir=ROOT/'.godot') as folder:
        work=Path(folder); examples=[]
        for p in documents:
            for code in re.findall(r'```gdscript\s*\n(.*?)\n```',p.read_text(),re.S):
                path=work/f'example-{count}.gd'; path.write_text(code+'\n')
                examples.append('res://'+path.relative_to(ROOT).as_posix()); count+=1
        source='extends Node\nfunc _ready() -> void:\n    await get_tree().process_frame\n    var examples: Array = '+json.dumps(examples)+'''
    var failures := 0
    for path in examples:
        var script = load(path)
        if script == null or not script.can_instantiate(): failures += 1
    print("GDSCRIPT_REFERENCE_VALIDATION: ",examples.size()," executable snippets, ",failures," failures")
    get_tree().quit(1 if failures else 0)
'''
        return count,run_doc_scene(work,source,'GDSCRIPT_REFERENCE_VALIDATION:')

def check_resources(documents,found):
    """Use the engine to load doc .tres examples and introspect all Resource exports."""
    import json
    command=shlex.split(os.environ.get('GODOT_COMMAND','godot'))
    with tempfile.TemporaryDirectory(prefix='handbook-resources-',dir=ROOT/'.godot') as folder:
        work=Path(folder); examples=[]
        for p in documents:
            for code in re.findall(r'```tres\s*\n(.*?)\n```',p.read_text(),re.S):
                path=work/f'example-{len(examples)}.tres'; path.write_text(code+'\n')
                examples.append('res://'+path.relative_to(ROOT).as_posix())
        expected={'res://'+p.relative_to(ROOT).as_posix():[row[0] for row in exports(text)] for p,text,_ in found.values()}
        source='extends Node\nfunc _ready() -> void:\n    await get_tree().process_frame\n    var expected: Dictionary = '+json.dumps(expected)+'\n    var examples: Array = '+json.dumps(examples)+'''
    var failures := 0
    var fields := 0
    for path in expected:
        var script = load(path)
        if script == null:
            failures += 1
            continue
        var value = script.new()
        if not value is Resource:
            failures += 1
            continue
        var actual: Array = []
        for property in value.get_property_list():
            if property.usage & PROPERTY_USAGE_EDITOR: actual.append(str(property.name))
        for name in expected[path]:
            fields += 1
            if name not in actual:
                print("MISSING_EXPORTED_PROPERTY ",path," ",name)
                failures += 1
    for path in examples:
        var example = load(path)
        if not example is Resource: failures += 1
        elif example is SpellData and not SpellValidator.validate(example).is_empty(): failures += 1
    print("RESOURCE_REFERENCE_VALIDATION: ",expected.size()," classes, ",fields," properties, ",examples.size()," examples, ",failures," failures")
    get_tree().quit(1 if failures else 0)
'''
        return run_doc_scene(work,source,'RESOURCE_REFERENCE_VALIDATION:')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-reference',action='store_true')
    parser.add_argument('--check-gdscript',action='store_true')
    parser.add_argument('--check-resources',action='store_true')
    args=parser.parse_args()
    if args.check_gdscript or args.check_resources: (ROOT/'.godot').mkdir(exist_ok=True)
    texts=sources(); found=schemas(texts); generated=generate_reference(found,texts)
    if args.write_reference:
        REFERENCE.parent.mkdir(parents=True,exist_ok=True); REFERENCE.write_text(generated)
    errors=[]
    if not REFERENCE.is_file() or REFERENCE.read_text()!=generated:
        errors.append('Resource reference differs from current schemas/notes; review and use --write-reference.')
    docs=[ROOT/'README.md',*sorted((ROOT/'docs').rglob('*.md'))]
    links,link_errors=validate_links(docs); errors.extend(link_errors)
    for name,(_,_,base) in found.items():
        guide=GUIDES.get(name,'spell-effects' if base=='SpellEffectDefinition' else '')
        if not guide or not (ROOT/'docs/authoring'/f'{guide}.md').is_file(): errors.append('No canonical guide for '+name)
    print(f'DOCS: {len(docs)} Markdown files, {links} local link/path checks, {len(found)} Resource classes, {sum(len(exports(t)) for _,t,_ in found.values())} exported properties')
    if args.check_gdscript:
        count,snippet_errors=check_snippets(docs); errors.extend(snippet_errors)
        print(f'GDSCRIPT: {count} executable snippets checked')
    if args.check_resources: errors.extend(check_resources(docs,found))
    for error in errors: print('FAIL '+error)
    print(f'DOCUMENTATION_VALIDATION: {len(errors)} errors')
    return 1 if errors else 0
if __name__=='__main__': raise SystemExit(main())
