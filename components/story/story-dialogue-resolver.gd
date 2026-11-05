@tool
class_name StoryDialogueResolver extends Node
@export var variants: Array[StoryDialogueVariant] = []
@export var enabled := true
func validate_variants() -> PackedStringArray:
 var errors := PackedStringArray()
 var ids := {}
 var priorities := {}
 for variant in variants:
  if variant == null or not variant.valid(): errors.append("Missing or invalid dialogue variant")
  elif ids.has(variant.variant_id): errors.append("Duplicate dialogue variant: " + String(variant.variant_id))
  else:
   ids[variant.variant_id] = true
   if priorities.has(variant.priority): errors.append("Dialogue variants share priority %d; ID ordering will decide: %s and %s" % [variant.priority, priorities[variant.priority], variant.variant_id])
   else: priorities[variant.priority] = String(variant.variant_id)
   for condition in variant.conditions:
    if condition == null or StoryDirector.registry == null or not StoryConditionEvaluator.validate_graph(condition, StoryDirector.registry): errors.append("Invalid condition in dialogue variant: " + String(variant.variant_id))
 return errors
func get_available_variants() -> Array[StoryDialogueVariant]:
 var result: Array[StoryDialogueVariant] = []
 if not enabled or not StoryDirector.is_ready(): return result
 for variant in variants:
  if variant == null or not variant.valid(): continue
  if variant.once_only and StoryDirector.has_completed_dialogue(String(variant.variant_id)): continue
  var passes := true
  for condition in variant.conditions:
   if condition == null or not StoryDirector.evaluate_condition(condition): passes = false; break
  if passes: result.append(variant)
 result.sort_custom(func(a: StoryDialogueVariant, b: StoryDialogueVariant): return a.priority > b.priority if a.priority != b.priority else String(a.variant_id) < String(b.variant_id))
 return result
func resolve_dialogue() -> StoryDialogueVariant:
 var available := get_available_variants()
 return available[0] if not available.is_empty() else null
func get_diagnostics() -> Dictionary:
 var selected := resolve_dialogue()
 return {"node": str(get_path()), "selected": String(selected.variant_id) if selected else "fallback", "errors": validate_variants()}
func start(dialogic: DialogicComponent) -> bool:
 if dialogic == null or SaveManager.loading or CutsceneFlow.sequence != null or QuestOfferDialog.is_open() or SceneManager.is_transitioning: return false
 var selected := resolve_dialogue()
 if selected == null: return false
 var completed := false
 if selected.timeline != null: completed = await dialogic.start_timeline(selected.timeline, "", selected.dialogue_identity)
 else: completed = await dialogic.start_direct_text(selected.direct_text, "", selected.dialogue_identity)
 if completed and selected.once_only and is_instance_valid(self) and StoryDirector.is_ready(): StoryDirector.complete_dialogue(String(selected.variant_id))
 return true
func _get_configuration_warnings() -> PackedStringArray: return validate_variants()
