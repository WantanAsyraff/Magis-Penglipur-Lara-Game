extends Control

@onready var app_list = %AppList
@onready var screen = %PhoneBG
@export var phone_selected: bool = false
@export var up_pos: Vector2 = Vector2(1388,450)
@export var down_pos: Vector2 = Vector2(1388,1000)
@export var edge_margin: float = 24.0
@export_range(32,160) var preview_height: float = 80.0
var current_app_node: Control = null
var _available := false
var _slide: Tween
var launcher: Button

func _ready() -> void:
	add_to_group("phone_ui")
	# App wiring must not depend on whether the story has enabled the phone yet.
	for child in app_list.get_children():
		if child is App: child.app_pressed.connect(_on_app_opened)
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()
	# The resting preview is the actual phone, rather than a separate HUD button.
	launcher = Button.new(); launcher.flat = true; launcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(launcher); launcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	launcher.pressed.connect(func(): if _can_open(): _set_open(true))
	_sync_availability()

func _can_open() -> bool:
	if not Player_Global_Data.phone_visible or not Player_Global_Data.is_alive(): return false
	if get_tree().paused or SaveManager.loading or SceneManager.is_transitioning: return false
	if QuestOfferDialog.is_open() or Dialogic.current_timeline != null: return false
	var modal := get_node_or_null("/root/ModalService")
	if modal != null and is_instance_valid(modal.holder): return false
	return true

func _process(_delta: float) -> void:
	_sync_availability()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_node_ready(): _sync_availability()

func _sync_availability() -> void:
	var allowed := _can_open()
	if not allowed and phone_selected: _set_open(false,false)
	_available = allowed
	visible = allowed
	if is_instance_valid(launcher):
		launcher.visible = allowed and not phone_selected
		for binding in InputMap.action_get_events("open_phone"):
			if binding is InputEventKey:
				launcher.tooltip_text = OS.get_keycode_string(binding.physical_keycode if binding.physical_keycode else binding.keycode)+" · Phone"; break

func _fit_to_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = screen.size
	var fit := minf(1.0,minf((viewport_size.x-edge_margin*2)/size.x,(viewport_size.y-edge_margin*2)/size.y))
	scale = Vector2.ONE*maxf(.1,fit)
	up_pos = Vector2(viewport_size.x-size.x*scale.x-edge_margin,viewport_size.y-size.y*scale.y-edge_margin)
	down_pos = Vector2(up_pos.x,viewport_size.y-preview_height*scale.y)
	if _slide: _slide.kill()
	position = up_pos if phone_selected else down_pos

func _unhandled_input(event: InputEvent) -> void:
	_sync_availability()
	if not _available: return
	if event.is_action_pressed("open_phone") and not event.is_echo():
		_set_open(not phone_selected)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and phone_selected:
		if current_app_node: _close_current_app()
		else: _set_open(false)
		get_viewport().set_input_as_handled()

func _set_open(value: bool, animate: bool = true) -> void:
	phone_selected = value
	if is_instance_valid(launcher): launcher.visible = _can_open() and not value
	if current_app_node: current_app_node.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	var focus := get_viewport().gui_get_focus_owner()
	if not value and is_instance_valid(focus) and is_ancestor_of(focus): focus.release_focus()
	if _slide: _slide.kill()
	if animate: _animate_phone()
	else: position = up_pos if value else down_pos

func _animate_phone() -> void:
	if _slide: _slide.kill()
	_slide = create_tween()
	_slide.tween_property(self,"position",up_pos if phone_selected else down_pos,.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_app_opened(app_resource: PackedScene) -> void:
	if not phone_selected or not _can_open() or current_app_node != null or app_resource == null: return
	var overlay := get_node_or_null("/root/InventoryOverlay")
	if overlay != null and app_resource.resource_path == "res://scenes/ui/inventory/inventory-ui.tscn":
		_set_open(false); overlay.open(); return
	if app_resource.resource_path in ["res://scenes/ui/player-stats-ui/player-stats-ui.tscn","res://scenes/ui/music-ui/music-selection-ui.tscn"]:
		_set_open(false)
		var page := load("res://scenes/ui/phone-ui/phone-app-overlay.gd").new() as CanvasLayer
		get_tree().root.add_child(page)
		if not page.present(app_resource): _set_open(true)
		return
	current_app_node = app_resource.instantiate()
	screen.add_child(current_app_node)
	current_app_node.visible = true
	current_app_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if current_app_node.has_signal("back_pressed"): current_app_node.back_pressed.connect(_close_current_app)
	app_list.visible = false

func _close_current_app() -> void:
	if current_app_node:
		current_app_node.queue_free()
		current_app_node = null
		app_list.visible = true
		if phone_selected and app_list.get_child_count() > 0:
			var first_icon = app_list.get_child(0)
			if first_icon is Control: first_icon.grab_focus()
