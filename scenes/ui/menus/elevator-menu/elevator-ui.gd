# ElevatorUI.gd
# A CanvasLayer scene that displays a floor selector panel.
# Call setup(floors) before adding to the tree, or connect signals after instantiation.
#
# Expected scene structure:
#   ElevatorUI (CanvasLayer)
#     └── PanelContainer (centered on screen)
#           └── VBoxContainer
#                 ├── HBoxContainer          ← title row
#                 │     ├── Label (name: TitleLabel)
#                 │     └── Button (name: CloseButton)
#                 └── VBoxContainer (name: FloorList)   ← buttons injected here
class_name ElevatorUI
extends CanvasLayer

# -------------------------
# SIGNALS
# -------------------------
signal floor_selected(scene_id: String, spawn_marker: String)
signal cancelled

# -------------------------
# NODES
# -------------------------
@onready var floor_list: VBoxContainer = %FloorList
@onready var title_label: Label = %TitleLabel
@onready var close_button: Button = %CloseButton

# -------------------------
# CONSTANTS
# -------------------------
const LOCK_ICON: String = "🔒"

# -------------------------
# BOOTSTRAP
# -------------------------
func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_cancelled)
	if title_label:
		title_label.text = "Select Floor"
	# Defer input consumption by one frame so the interact press
	# that opened us doesn't get immediately swallowed
	set_process_unhandled_input(false)
	await get_tree().process_frame
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancelled()
		get_viewport().set_input_as_handled()

# -------------------------
# SETUP
# -------------------------
func setup(floors: Array[ElevatorFloor]) -> void:
	# May be called before _ready if instantiated and setup() called same frame
	await ready

	if not floor_list:
		push_error("ElevatorUI: FloorList node not found.")
		return

	# Clear any existing buttons
	for child in floor_list.get_children():
		child.queue_free()

	for floor_data in floors:
		_add_floor_button(floor_data)

# -------------------------
# FLOOR BUTTONS
# -------------------------
func _add_floor_button(floor_data: ElevatorFloor) -> void:
	var btn := Button.new()

	if floor_data.locked:
		btn.text = "%s  %s" % [LOCK_ICON, floor_data.floor_name]
		btn.disabled = true
		btn.tooltip_text = floor_data.locked_hint
		# Dim the button visually
		btn.modulate = Color(1, 1, 1, 0.45)
	else:
		btn.text = floor_data.floor_name
		btn.disabled = false
		btn.pressed.connect(
			func(): _on_floor_pressed(floor_data.scene_id, floor_data.spawn_marker_override)
		)

	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 48)
	floor_list.add_child(btn)

# -------------------------
# CALLBACKS
# -------------------------
func _on_floor_pressed(scene_id: String, spawn_marker: String) -> void:
	floor_selected.emit(scene_id, spawn_marker)

func _on_cancelled() -> void:
	cancelled.emit()
