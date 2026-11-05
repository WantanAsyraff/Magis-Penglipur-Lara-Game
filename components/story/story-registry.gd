class_name StoryRegistry extends RefCounted
var database: StoryDatabase
var arcs: Dictionary = {}
var chapters: Dictionary = {}
var stages: Dictionary = {}
var flags: Dictionary = {}
var choices: Dictionary = {}
var transitions: Dictionary = {}
var transition_sources: Dictionary = {}
var actions: Dictionary = {}
var errors: PackedStringArray = []
func _init(source: StoryDatabase = null) -> void:
 database = source
 if source: rebuild()
func rebuild() -> PackedStringArray:
 arcs.clear(); chapters.clear(); stages.clear(); flags.clear(); choices.clear(); transitions.clear(); transition_sources.clear(); actions.clear(); errors.clear()
 if database == null:
  errors.append("StoryDatabase is missing")
  return errors
 for arc in database.arcs:
  if arc == null:
   errors.append("Null arc")
   continue
  var aid := String(arc.arc_id)
  if not _id(aid) or arcs.has(aid):
   errors.append("Invalid or duplicate arc: " + aid)
   continue
  arcs[aid] = arc
  var local_chapters := {}
  for chapter in arc.chapters:
   if chapter == null:
    errors.append(aid + ": null chapter")
    continue
   var cid := String(chapter.chapter_id)
   if not _id(cid) or chapters.has(cid):
    errors.append(aid + ": invalid or duplicate chapter: " + cid)
    continue
   chapters[cid] = chapter
   local_chapters[cid] = true
   var local_stages := {}
   for stage in chapter.stages:
    if stage == null:
     errors.append(cid + ": null stage")
     continue
    var sid := String(stage.stage_id)
    if not _id(sid) or stages.has(sid):
     errors.append(cid + ": invalid or duplicate stage: " + sid)
     continue
    stages[sid] = stage
    local_stages[sid] = true
   if not local_stages.has(String(chapter.initial_stage_id)): errors.append(cid + ": initial stage missing: " + String(chapter.initial_stage_id))
  if not local_chapters.has(String(arc.initial_chapter_id)): errors.append(aid + ": initial chapter missing: " + String(arc.initial_chapter_id))
 for flag in database.flags:
  if flag == null:
   errors.append("Null flag")
   continue
  var fid := String(flag.flag_id)
  if not _id(fid) or flags.has(fid) or not fid.begins_with("story."):
   errors.append("Invalid or duplicate flag: " + fid)
   continue
  if not flag.valid_value(flag.default_value) or (flag.scope == StoryFlagDefinition.Scope.CAMPAIGN and flag.value_type != StoryFlagDefinition.ValueType.BOOLEAN) or (flag.scope == StoryFlagDefinition.Scope.PERSISTENT_TYPED and flag.value_type == StoryFlagDefinition.ValueType.BOOLEAN):
   errors.append(fid + ": invalid default or persistent type")
  flags[fid] = flag
 for choice in database.choices:
  if choice == null or not _id(String(choice.choice_id)) or choices.has(String(choice.choice_id)):
   errors.append("Invalid or duplicate story choice")
   continue
  choices[String(choice.choice_id)] = choice
  var options := {}
  for option in choice.options:
   if option == null or not _id(String(option.option_id)) or options.has(String(option.option_id)): errors.append(String(choice.choice_id) + ": invalid or duplicate option")
   elif option != null: options[String(option.option_id)] = true
 _validate_transitions()
 return errors
func _validate_transitions() -> void:
 var ids := {}
 for sid in stages:
  var stage: StoryStageData = stages[sid]
  var priorities := {}
  for transition in stage.transitions:
   if transition == null:
    errors.append(sid + ": null transition")
    continue
   var tid := String(transition.transition_id)
   if not _id(tid) or ids.has(tid): errors.append(sid + ": invalid or duplicate transition: " + tid)
   ids[tid] = true
   transitions[tid] = transition
   transition_sources[tid] = sid
   if not stages.has(String(transition.target_stage_id)): errors.append(tid + ": unknown destination " + String(transition.target_stage_id))
   if transition.automatic and transition.conditions.is_empty() and transition.required_event_target.is_empty() and transition.required_choice_id.is_empty():
    errors.append(tid + ": unconditional automatic transition is unsafe")
   if transition.automatic and transition.conditions.is_empty() and transition.required_event_target.is_empty():
    if priorities.has(transition.priority): errors.append(sid + ": ambiguous automatic priority " + str(transition.priority))
    priorities[transition.priority] = true
   for condition in transition.conditions:
    if not StoryConditionEvaluator.validate_graph(condition, self): errors.append(tid + ": invalid condition")
   for action in stage.on_exit_actions + transition.actions + stages.get(String(transition.target_stage_id), stage).on_enter_actions:
    if action == null or not action.validate(self).is_empty(): errors.append(tid + ": invalid action")
    elif action.required:
     if not _id(String(action.action_id)) or actions.has(String(action.action_id)) and actions[String(action.action_id)] != action: errors.append(tid + ": required action needs unique stable ID")
     else: actions[String(action.action_id)] = action
func _id(id: String) -> bool:
 if id.is_empty() or id.length() > 128 or id != id.to_lower(): return false
 for c in id:
  if not (c >= "a" and c <= "z" or c >= "0" and c <= "9" or c in "._-"): return false
 return true
func get_arc(id: StringName) -> StoryArcData: return arcs.get(String(id))
func get_chapter(id: StringName) -> StoryChapterData: return chapters.get(String(id))
func get_stage(id: StringName) -> StoryStageData: return stages.get(String(id))
func get_flag_definition(id: StringName) -> StoryFlagDefinition: return flags.get(String(id))
func get_choice(id: StringName) -> StoryChoiceData: return choices.get(String(id))
func validate_all() -> PackedStringArray: return rebuild()
