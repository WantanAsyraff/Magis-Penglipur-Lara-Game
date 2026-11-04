class_name RepetoirePanel
extends Control

const SPELL_SLOT = preload("res://scenes/ui/spell-combat-ui/spell-slot.tscn")
@onready var grid: GridContainer = %RepetoireGrid
var repertoire_enabled := true
var heading: Label
var slide_tween: Tween
var _target_visible := false
var slide_progress := 0.0:
	set(value):
		slide_progress = value
		_apply_slide()

func _ready() -> void:
	Player_Global_Data.spells_updated.connect(_populate_grid)
	get_viewport().size_changed.connect(_layout)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 18)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	$Scroll.offset_top = 32
	_layout()
	_populate_grid()
	_refresh()

func _layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_apply_slide()
	offset_top = -444
	offset_bottom = -24

func _apply_slide() -> void:
	offset_left = -374 + 374 * slide_progress
	offset_right = -24 + 374 * slide_progress

func _present(show_panel: bool, animate: bool) -> void:
	_target_visible = show_panel
	if slide_tween: slide_tween.kill()
	if not animate:
		slide_progress = 0.0 if show_panel else 1.0
		visible = show_panel
		return
	show()
	slide_tween = create_tween()
	slide_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if show_panel else Tween.EASE_IN)
	slide_tween.tween_property(self, "slide_progress", 0.0 if show_panel else 1.0, 0.24)
	if not show_panel: slide_tween.tween_callback(hide)

func _available() -> bool:
	return Player_Global_Data.combat_mode and Player_Global_Data.is_alive() and not get_tree().paused and Dialogic.current_timeline == null and not QuestOfferDialog.is_open() and not SaveManager.loading

func _process(_delta: float) -> void:
	_refresh()

func _refresh(animate: bool = false) -> void:
	var should_show := repertoire_enabled and _available()
	if should_show != _target_visible:
		_present(should_show, animate)
	elif not _available() and visible:
		_present(false, false)
	var key := ""
	for binding in InputMap.action_get_events("toggle_repertoire"):
		if binding is InputEventKey:
			key = OS.get_keycode_string(binding.physical_keycode if binding.physical_keycode else binding.keycode)
			break
	heading.text = "Repertoire" + (" · " + key if not key.is_empty() else "")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_repertoire") or event.is_echo(): return
	if not _available() or is_instance_valid(ModalService.holder): return
	repertoire_enabled = not repertoire_enabled
	_refresh(true)
	get_viewport().set_input_as_handled()

func _populate_grid() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for spell in Player_Global_Data.equipped_spells:
		var slot = SPELL_SLOT.instantiate()
		grid.add_child(slot)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_spell(spell)
