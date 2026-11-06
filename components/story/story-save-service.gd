class_name StorySaveService extends RefCounted
const VERSION := 1
const MAX_VALUES := 256
const MAX_RECEIPTS := 4096
static func defaults(registry: StoryRegistry) -> Dictionary:
 if registry == null or not registry.errors.is_empty() or registry.database.arcs.is_empty(): return {}
 var arc: StoryArcData = registry.database.arcs[0]
 var chapter := registry.get_chapter(arc.initial_chapter_id)
 if chapter == null: return {}
 return {"version": VERSION, "active_arc_id": String(arc.arc_id), "active_chapter_id": String(chapter.chapter_id), "active_stage_id": String(chapter.initial_stage_id), "variables": {}, "choices": {}, "completed_transitions": [], "completed_actions": [], "completed_dialogues": [], "objective_id": "", "objective_text": ""}
static func encode(state: StoryState, registry: StoryRegistry) -> Dictionary:
 if state.lifecycle != StoryState.Lifecycle.READY: return {}
 var data := {"version": VERSION, "active_arc_id": String(state.arc_id), "active_chapter_id": String(state.chapter_id), "active_stage_id": String(state.stage_id), "variables": {}, "choices": {}, "completed_transitions": state.receipts.keys(), "completed_actions": state.action_receipts.keys(), "completed_dialogues": state.dialogue_receipts.keys(), "objective_id": String(state.objective_id), "objective_text": state.objective_text}
 for id in state.choices: data.choices[String(id)] = String(state.choices[id])
 for id in state._transient:
  var definition := registry.get_flag_definition(StringName(id))
  if definition != null and definition.scope == StoryFlagDefinition.Scope.PERSISTENT_TYPED: data.variables[String(id)] = state._transient[id]
 return data
static func stage(raw: Variant, registry: StoryRegistry, legacy_quest: Dictionary = {}) -> Dictionary:
 if registry == null or not registry.errors.is_empty(): return {}
 if raw == null:
  raw = defaults(registry)
  if raw.is_empty(): return {}
  var flags: Dictionary = legacy_quest.get("world_flags", {})
  if flags.get("story_sequence:prologue.after_final_paper", false): raw.active_stage_id = "prologue.after_exam"
  elif flags.get("story_sequence:prologue.school", false): raw.active_stage_id = "prologue.spm_practical"
  elif flags.get("story.prologue.reached_school", false): raw.active_stage_id = "prologue.reach_school"
  elif flags.get("story_sequence:prologue.kampung", false): raw.active_stage_id = "prologue.leave_house"
 elif raw is Dictionary:
  raw = raw.duplicate(true)
 if raw is Dictionary and registry.database.migrations != null:
  raw = migrate_ids(raw, registry.database.migrations)
  if raw.is_empty(): return {}
 if not raw is Dictionary or raw.get("version") != VERSION: return {}
 if not raw.has("completed_dialogues"): raw.completed_dialogues = []
 if raw.size() != 11 or not raw.completed_dialogues is Array or raw.completed_dialogues.size() > MAX_RECEIPTS: return {}
 var seen_dialogues := {}
 for id in raw.completed_dialogues:
  if not id is String or not registry._id(id) or seen_dialogues.has(id): return {}
  seen_dialogues[id] = true
 if not raw.get("objective_id") is String or String(raw.objective_id).length() > 128 or not raw.get("objective_text") is String or String(raw.objective_text).length() > 1024: return {}
 for key in ["active_arc_id", "active_chapter_id", "active_stage_id"]:
  if not raw.get(key) is String or String(raw[key]).is_empty() or String(raw[key]).length() > 128: return {}
 var arc := registry.get_arc(StringName(raw.active_arc_id))
 var chapter := registry.get_chapter(StringName(raw.active_chapter_id))
 var stage_data := registry.get_stage(StringName(raw.active_stage_id))
 if arc == null or chapter == null or stage_data == null or chapter not in arc.chapters or stage_data not in chapter.stages: return {}
 for key in ["variables", "choices"]:
  if not raw.get(key) is Dictionary or raw[key].size() > MAX_VALUES: return {}
 for key in ["completed_transitions", "completed_actions"]:
  if not raw.get(key) is Array or raw[key].size() > MAX_RECEIPTS: return {}
 for id in raw.variables:
  if not id is String: return {}
  var definition := registry.get_flag_definition(StringName(id))
  if definition == null or definition.scope != StoryFlagDefinition.Scope.PERSISTENT_TYPED: return {}
  var value: Variant = raw.variables[id]
  if definition.value_type == StoryFlagDefinition.ValueType.INTEGER and value is float and is_finite(value) and value == floorf(value) and absf(value) <= 9007199254740991.0:
   value = int(value)
  if not definition.valid_value(value): return {}
  raw.variables[id] = value
 for id in raw.choices:
  if not id is String or not raw.choices[id] is String: return {}
  var choice := registry.get_choice(StringName(id))
  if choice == null or not choice.options.any(func(option: StoryChoiceOptionData): return option != null and String(option.option_id) == raw.choices[id]): return {}
 for key in ["completed_transitions", "completed_actions"]:
  var seen := {}
  for id in raw[key]:
   if not id is String or id.is_empty() or id.length() > 384 or seen.has(id): return {}
   var parts: PackedStringArray = String(id).split(":")
   if (key == "completed_transitions" and parts.size() != 3) or (key == "completed_actions" and parts.size() != 4): return {}
   var receipt_arc := registry.get_arc(StringName(parts[0]))
   var receipt_chapter := registry.get_chapter(StringName(parts[1]))
   if receipt_arc == null or receipt_chapter == null or receipt_chapter not in receipt_arc.chapters or not registry.transitions.has(parts[2]): return {}
   var source_stage := registry.get_stage(StringName(registry.transition_sources.get(parts[2], "")))
   if source_stage == null or source_stage not in receipt_chapter.stages: return {}
   if key == "completed_actions":
    var transition: StoryTransitionData = registry.transitions[parts[2]]
    var destination := registry.get_stage(transition.target_stage_id)
    if destination == null or not registry.actions.has(parts[3]): return {}
    var possible: Array = source_stage.on_exit_actions + transition.actions + destination.on_enter_actions
    if not possible.any(func(action: StoryAction): return action != null and String(action.action_id) == parts[3]): return {}
   seen[id] = true
 return raw.duplicate(true)
static func migrate_ids(data: Dictionary, migrations: StoryIdMigrations) -> Dictionary:
 var copy := data.duplicate(true)
 for field in ["active_arc_id", "active_chapter_id", "active_stage_id"]:
  if not copy.get(field) is String: return {}
  var kind: String = {"active_arc_id": "arcs", "active_chapter_id": "chapters", "active_stage_id": "stages"}[field]
  copy[field] = migrations.mapped(kind, copy[field])
 for field in ["variables", "choices"]:
  if not copy.get(field) is Dictionary: return {}
  var mapped := {}
  for id in copy[field]:
   if not id is String: return {}
   var target := migrations.mapped(field, id)
   if mapped.has(target): return {}
   mapped[target] = migrations.mapped("options", String(copy[field][id])) if field == "choices" and copy[field][id] is String else copy[field][id]
  copy[field] = mapped
 for field in ["completed_transitions", "completed_actions"]:
  if not copy.get(field) is Array: return {}
  var mapped: Array = []
  for receipt in copy[field]:
   if not receipt is String: return {}
   var parts := String(receipt).split(":")
   if parts.size() != (3 if field == "completed_transitions" else 4): return {}
   parts[0] = migrations.mapped("arcs", parts[0])
   parts[1] = migrations.mapped("chapters", parts[1])
   parts[2] = migrations.mapped("transitions", parts[2])
   if parts.size() == 4: parts[3] = migrations.mapped("actions", parts[3])
   var target := ":".join(parts)
   if target in mapped: return {}
   mapped.append(target)
  copy[field] = mapped
 if copy.has("completed_dialogues"):
  if not copy.completed_dialogues is Array: return {}
  var mapped_dialogues: Array = []
  for id in copy.completed_dialogues:
   if not id is String: return {}
   var mapped_id := migrations.mapped("dialogues", id)
   if mapped_id in mapped_dialogues: return {}
   mapped_dialogues.append(mapped_id)
  copy.completed_dialogues = mapped_dialogues
 return copy
static func apply(state: StoryState, data: Dictionary) -> void:
 state.arc_id = StringName(data.active_arc_id)
 state.chapter_id = StringName(data.active_chapter_id)
 state.stage_id = StringName(data.active_stage_id)
 state._transient.clear()
 for id in data.variables: state._transient[StringName(id)] = data.variables[id]
 state.choices = data.choices.duplicate(true)
 state.receipts.clear()
 for id in data.completed_transitions: state.receipts[id] = true
 state.action_receipts.clear()
 for id in data.completed_actions: state.action_receipts[id] = true
 state.dialogue_receipts.clear()
 for id in data.completed_dialogues: state.dialogue_receipts[id] = true
 state.objective_id = StringName(data.objective_id)
 state.objective_text = data.objective_text
 state.lifecycle = StoryState.Lifecycle.READY
static func capture_runtime(state: StoryState) -> Dictionary:
 return {"lifecycle": state.lifecycle, "arc": state.arc_id, "chapter": state.chapter_id, "stage": state.stage_id, "variables": state._transient.duplicate(true), "choices": state.choices.duplicate(true), "transitions": state.receipts.duplicate(true), "actions": state.action_receipts.duplicate(true), "dialogues": state.dialogue_receipts.duplicate(true), "objective_id": state.objective_id, "objective_text": state.objective_text}
static func restore_runtime(state: StoryState, previous: Dictionary) -> void:
 state.lifecycle = previous.lifecycle
 state.arc_id = previous.arc
 state.chapter_id = previous.chapter
 state.stage_id = previous.stage
 state._transient = previous.variables.duplicate(true)
 state.choices = previous.choices.duplicate(true)
 state.receipts = previous.transitions.duplicate(true)
 state.action_receipts = previous.actions.duplicate(true)
 state.dialogue_receipts = previous.dialogues.duplicate(true)
 state.objective_id = previous.objective_id
 state.objective_text = previous.objective_text
