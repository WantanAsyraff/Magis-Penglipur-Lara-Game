extends Node
# -------------------------
# SIGNALS
# -------------------------
signal custom_signal_emitted(signal_key: String)
signal combat_mode_changed(is_combat: bool)
signal casting_changed(is_casting: bool)
signal mana_changed(new_value: float)
signal health_changed(new_value: int)
signal spells_updated()
signal progression_changed()
var academic_comprehension: Dictionary[StringName, int] = {}
var completed_subjects: Array[String] = []
var active_buffs: Dictionary = {}
signal dash_charges_changed(current: int)

# -------------------------
# PHONE
# -------------------------
var phone_visible: bool = true

# -------------------------
# NPC REGISTRY
# -------------------------
var active_npc_ids: Array[String] = []

func register_npc(npc_id: String) -> bool:
	if active_npc_ids.has(npc_id):
		return false
	active_npc_ids.append(npc_id)
	return true

func unregister_npc(npc_id: String) -> void:
	active_npc_ids.erase(npc_id)

# -------------------------
# SCENE HISTORY
# -------------------------
var previous_scene: String = ""
var previous_position: Vector2 = Vector2.ZERO
var current_scene: String = "":
	set(value):
		previous_scene = current_scene
		previous_position = Player_Manager.last_player_position
		current_scene = value

# -------------------------
# GOALS
# -------------------------
signal goals_changed(goals: Array[String])
var active_goals: Array[String] = []:
	set(value):
		active_goals = value
		goals_changed.emit(active_goals)

func set_goal(goal: String) -> void:
	active_goals = [goal]

func add_goal(goal: String) -> void:
	if not active_goals.has(goal):
		active_goals.append(goal)
		goals_changed.emit(active_goals)

func clear_goals() -> void:
	active_goals = []

# -------------------------
# SELECTED SPELL (transient)
# -------------------------
var selected_spell: SpellData = null

# -------------------------
# IDENTITY
# -------------------------
var p_name: String
var p_role: String
var p_curr_ringgit: float = 0
var p_mood: String
# -------------------------
# PROGRESSION
# -------------------------
var player_level: int = 1
var player_exp: float = 9999:
	set(value):
		player_exp = maxf(value, 0.0)
		progression_changed.emit()
var completed_quests: Array[String] = []
var active_quest_states: Dictionary = {}   # quest_id -> {obj_id: progress} for saving
# -------------------------
# FLAGS
# -------------------------
var p_moveable: bool = true
var p_jumpable: bool = true
var p_visible: bool = true
var p_invincible: bool = false
var p_hidden: bool = false
signal world_changed(world_name: String)
var current_world: String = "":
	set(value):
		current_world = value
		emit_signal("world_changed", value)

# -------------------------
# DASHES
# -------------------------
var is_dashing: bool = false
var MAX_DASH_CHARGES := 3
var current_dash_charges := MAX_DASH_CHARGES :
	set(value):
		current_dash_charges = value
		dash_charges_changed.emit(current_dash_charges)
# -------------------------
# CASTING  (guarded setter)
# -------------------------
var _is_casting := false
var is_casting: bool:
	set(value):
		if _is_casting == value:
			return
		_is_casting = value
		casting_changed.emit(value)
	get:
		return _is_casting
# -------------------------
# COMBAT MODE  (guarded setter)
# -------------------------
var _combat_mode := false
var combat_mode: bool:
	set(value):
		if _combat_mode == value:
			return
		_combat_mode = value
		combat_mode_changed.emit(value)
	get:
		return _combat_mode
# -------------------------
# MOVEMENT
# -------------------------
var p_position: Vector2
var p_speed: float = 900.0
var p_jump_height: float = -2500.0
var p_size: float = 1.0
# -------------------------
# HEALTH
# -------------------------
var p_max_health: int = 400
var p_curr_health: int = p_max_health:
	set(value):
		p_curr_health = clamp(value, 0, p_max_health)
		health_changed.emit(p_curr_health)
# -------------------------
# MANA
# -------------------------
var p_max_mana: float = 400.0
var p_curr_mana: float = p_max_mana:
	set(value):
		p_curr_mana = clamp(value, 0.0, p_max_mana)
		mana_changed.emit(p_curr_mana)
# -------------------------
# ACADEMIC
# -------------------------
var current_field: String
var current_major: String
var current_minor: String
# -------------------------
# SPELLS
# -------------------------
var learned_spells: Array[SpellData] = []
var equipped_spells: Array[SpellData] = []

func add_spell(spell: SpellData) -> void:
	if learned_spells.has(spell):
		return
	learned_spells.append(spell)
	print("Global learned spell: ", spell.spell_name)
	spells_updated.emit()

func add_spells(spells: Array[SpellData]) -> void:
	for s in spells:
		if learned_spells.has(s):
			continue
		learned_spells.append(s)
		print("Global learned spell: ", s.spell_name)
	spells_updated.emit()

func remove_spell(spell: SpellData) -> void:
	if not learned_spells.has(spell):
		return
	if equipped_spells.has(spell):
		equipped_spells.erase(spell)
	learned_spells.erase(spell)
	print("Global removed spell: ", spell.spell_name)
	spells_updated.emit()

func has_spell(spell: SpellData) -> bool:
	return learned_spells.has(spell)

func equip_spell(spell: SpellData) -> void:
	if not learned_spells.has(spell):
		push_error("Cannot equip spell not in learned_spells: " + spell.spell_name)
		return
	if equipped_spells.has(spell):
		return
	equipped_spells.append(spell)
	print("Equipped spell: ", spell.spell_name)
	spells_updated.emit()

func unequip_spell(spell: SpellData) -> void:
	if not equipped_spells.has(spell):
		return
	equipped_spells.erase(spell)
	print("Unequipped spell: ", spell.spell_name)
	spells_updated.emit()

func is_spell_equipped(spell: SpellData) -> bool:
	return equipped_spells.has(spell)
# -------------------------
# MANA HELPERS
# -------------------------
func consume_mana(amount: float) -> bool:
	if not is_finite(amount) or amount < 0 or p_curr_mana < amount:
		return false
	p_curr_mana -= amount
	return true

func restore_mana(amount: float) -> void:
	p_curr_mana += amount
# -------------------------
# HEALTH HELPERS
# -------------------------
func take_damage(amount: int) -> void:
	if p_invincible:
		return
	p_curr_health -= amount

func restore_health(amount: int) -> void:
	p_curr_health += amount

func is_alive() -> bool:
	return p_curr_health > 0
# -------------------------
# RESET
# -------------------------
func reset() -> void:
	academic_comprehension.clear()
	completed_subjects.clear()
	active_buffs.clear()
	progression_changed.emit()
	p_curr_health = p_max_health
	p_curr_mana = p_max_mana
	learned_spells.clear()
	equipped_spells.clear()
	is_casting = false
	combat_mode = false
	spells_updated.emit()

# All purchase callers share one atomic validation and application path.
func get_subject_cost(data: subjectData) -> int:
	if data == null:
		return 0
	var multipliers := {"Novice": 1.0, "Intermediate": 1.5, "Advanced": 2.25, "Expert": 3.5}
	return int(30 * pow(maxi(data.difficulty_level, 1), 2) * multipliers.get(data.magis_comprehension, 1.0) * (1.0 + data.contained_spells.size() * 0.25))

func has_completed_subject(id: String) -> bool:
	return completed_subjects.has(id)

func can_purchase_subject(data: subjectData, course: CourseData = null) -> bool:
	if data == null or data.subject_id.is_empty() or has_completed_subject(data.subject_id):
		return false
	if course != null:
		if not course.subjects.has(data) or not AcademicValidator.validate_course(course).is_empty():
			return false
		for id in course.prerequisites:
			if not has_completed_subject(id):
				return false
	for field_id in data.comprehension_requirements:
		if academic_comprehension.get(field_id, 0) < data.comprehension_requirements[field_id]:
			return false
	for id in data.prerequisites:
		if not has_completed_subject(id):
			return false
	for spell in data.contained_spells:
		if spell == null:
			return false
	return player_exp >= get_subject_cost(data)

func purchase_subject(data: subjectData, course: CourseData = null) -> bool:
	if not can_purchase_subject(data, course):
		return false
	# Commit completion before emitting signals, including the XP setter signal.
	completed_subjects.append(data.subject_id)
	player_exp -= get_subject_cost(data)
	add_spells(data.contained_spells)
	progression_changed.emit()
	return true

func set_comprehension(field_id: StringName, rank: int) -> void:
	if field_id == &"":
		return
	academic_comprehension[field_id] = maxi(rank, 0)
	progression_changed.emit()
