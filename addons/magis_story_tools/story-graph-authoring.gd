@tool
class_name StoryGraphAuthoring extends RefCounted
## Changes only the authored database. The stage owns its transition subresources.
static func find_stage(database: StoryDatabase, id: String) -> Dictionary:
	if database == null: return {}
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage != null and String(stage.stage_id) == id:
					return {"stage": stage, "chapter": chapter, "arc": arc}
	return {}

static func transitions_between(stage: StoryStageData, target_id: String) -> Array[StoryTransitionData]:
	var result: Array[StoryTransitionData] = []
	if stage != null:
		for transition in stage.transitions:
			if transition != null and String(transition.target_stage_id) == target_id: result.append(transition)
	return result

static func connection_error(database: StoryDatabase, source_id: String, target_id: String) -> String:
	var source := find_stage(database, source_id)
	var target := find_stage(database, target_id)
	if source.is_empty(): return "Source stage no longer exists: " + source_id
	if target.is_empty(): return "Target stage no longer exists: " + target_id
	if source_id == target_id: return "Self-transitions need an explicit trigger; configure them in the stage Inspector"
	if not transitions_between(source.stage, target_id).is_empty(): return "This pair already has a transition; select it in the transition list"
	return ""

static func next_id(database: StoryDatabase, source_id: String, target_id: String) -> StringName:
	var used := {}
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for stage in chapter.stages:
				if stage == null: continue
				for transition in stage.transitions:
					if transition != null: used[String(transition.transition_id)] = true
	var base := source_id + ".to." + target_id
	if base.length() > 112:
		base = base.substr(0, 100) + "." + ("%08x" % base.hash())
	var candidate := base
	var suffix := 2
	while used.has(candidate):
		candidate = base + "." + str(suffix)
		suffix += 1
	return StringName(candidate)

static func set_registered(database: StoryDatabase, source: StoryStageData, transition: StoryTransitionData, present: bool) -> Error:
	if database == null or source == null or transition == null or database.resource_path.is_empty(): return ERR_INVALID_PARAMETER
	var ownership := _owner_for(database, source)
	if ownership.is_empty(): return ERR_FILE_NOT_FOUND
	var previous := source.transitions.duplicate()
	var updated := previous.duplicate()
	var index := updated.find(transition)
	if present and index < 0: updated.append(transition)
	elif not present and index >= 0: updated.remove_at(index)
	else: return OK
	source.transitions = updated
	var result := ResourceSaver.save(ownership.resource, ownership.path)
	if result != OK:
		source.transitions = previous
		return result
	return OK

static func save_owner(database: StoryDatabase, source: StoryStageData) -> Error:
	if database == null or source == null or database.resource_path.is_empty(): return ERR_INVALID_PARAMETER
	var ownership := _owner_for(database, source)
	if ownership.is_empty(): return ERR_FILE_NOT_FOUND
	return ResourceSaver.save(ownership.resource, ownership.path)

static func reassign(database: StoryDatabase, old_source: StoryStageData, new_source: StoryStageData, transition: StoryTransitionData) -> Error:
	if database == null or old_source == null or new_source == null or transition == null or transition not in old_source.transitions: return ERR_INVALID_PARAMETER
	if old_source == new_source: return OK
	var old_owner := _owner_for(database, old_source)
	var new_owner := _owner_for(database, new_source)
	if old_owner.is_empty() or new_owner.is_empty() or old_owner.path != new_owner.path: return ERR_UNAVAILABLE
	var old_array := old_source.transitions.duplicate()
	var new_array := new_source.transitions.duplicate()
	var updated_old := old_array.duplicate(); updated_old.erase(transition)
	var updated_new := new_array.duplicate(); updated_new.append(transition)
	old_source.transitions = updated_old
	new_source.transitions = updated_new
	var result := ResourceSaver.save(old_owner.resource, old_owner.path)
	if result != OK:
		old_source.transitions = old_array
		new_source.transitions = new_array
	return result

static func _owner_for(database: StoryDatabase, source: StoryStageData) -> Dictionary:
	var source_path := source.resource_path
	if source_path.is_empty() or source_path.begins_with(database.resource_path + "::"):
		return {"resource": database, "path": database.resource_path}
	var owner_path := source_path.get_slice("::", 0)
	var owner: Resource = source if owner_path == source_path else load(owner_path)
	if owner == null: return {}
	return {"resource": owner, "path": owner_path}

static func stage_id_error(database: StoryDatabase, id: String) -> String:
	if id.is_empty() or id.length() > 128 or id != id.to_lower(): return "Stage ID must be 1–128 lowercase characters."
	for c in id:
		if not (c >= "a" and c <= "z" or c >= "0" and c <= "9" or c in "._-"):
			return "Stage ID may contain only lowercase letters, digits, periods, underscores and hyphens."
	if not find_stage(database, id).is_empty(): return "Stage ID already exists: " + id
	return ""

static func find_chapter(database: StoryDatabase, id: String) -> Dictionary:
	if database == null: return {}
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter != null and String(chapter.chapter_id) == id:
				return {"arc": arc, "chapter": chapter}
	return {}

static func set_stage_registered(database: StoryDatabase, chapter: StoryChapterData, stage: StoryStageData, present: bool) -> Error:
	if database == null or chapter == null or stage == null or database.resource_path.is_empty(): return ERR_INVALID_PARAMETER
	var owner := _owner_for_chapter(database, chapter)
	if owner.is_empty(): return ERR_FILE_NOT_FOUND
	var previous := chapter.stages.duplicate()
	var updated := previous.duplicate()
	var index := updated.find(stage)
	if present and index < 0: updated.append(stage)
	elif not present and index >= 0: updated.remove_at(index)
	else: return OK
	chapter.stages = updated
	var result := ResourceSaver.save(owner.resource, owner.path)
	if result != OK: chapter.stages = previous
	return result

static func set_chapter_entry(database: StoryDatabase, chapter: StoryChapterData, id: StringName) -> Error:
	if database == null or chapter == null: return ERR_INVALID_PARAMETER
	if not chapter.stages.any(func(stage: StoryStageData): return stage != null and stage.stage_id == id): return ERR_DOES_NOT_EXIST
	var owner := _owner_for_chapter(database, chapter)
	if owner.is_empty(): return ERR_FILE_NOT_FOUND
	var previous := chapter.initial_stage_id
	chapter.initial_stage_id = id
	var result := ResourceSaver.save(owner.resource, owner.path)
	if result != OK: chapter.initial_stage_id = previous
	return result

static func stage_dependencies(database: StoryDatabase, stage: StoryStageData) -> PackedStringArray:
	var result := PackedStringArray()
	if database == null or stage == null: return result
	var owner := find_stage(database, String(stage.stage_id))
	if not owner.is_empty() and owner.chapter.initial_stage_id == stage.stage_id: result.append("Chapter entry stage")
	for transition in stage.transitions:
		if transition != null: result.append("Outgoing transition " + String(transition.transition_id))
	for arc in database.arcs:
		if arc == null: continue
		for chapter in arc.chapters:
			if chapter == null: continue
			for source in chapter.stages:
				if source == null or source == stage: continue
				for transition in source.transitions:
					if transition != null and transition.target_stage_id == stage.stage_id:
						result.append("Incoming transition " + String(transition.transition_id))
	return result

static func _owner_for_chapter(database: StoryDatabase, chapter: StoryChapterData) -> Dictionary:
	if database.resource_path.is_empty(): return {}
	var path := chapter.resource_path
	if path.is_empty() or path.begins_with(database.resource_path + "::"):
		return {"resource": database, "path": database.resource_path}
	var owner_path := path.get_slice("::", 0)
	var owner: Resource = chapter if owner_path == path else load(owner_path)
	if owner == null: return {}
	return {"resource": owner, "path": owner_path}
