class_name PanelTutorial extends Control

signal closed

@export var data: TutorialData

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var texture_rect: TextureRect = %TextureRect
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton
@onready var done_button: Button = %DoneButton
@onready var page_indicator: Label = %PageIndicator
@onready var close_button: Button = %CloseButton
@onready var panel_anim: AnimationPlayer = %AnimationPlayer

var _current_page: int = 0

func _ready() -> void:
	if data == null or data.pages.is_empty():
		push_warning("PanelTutorial: no TutorialData assigned or pages array is empty.")
		return
	_show_page(_current_page)
	_update_buttons()

func _show_page(index: int) -> void:
	var page: TutorialPage = data.pages[index]

	if title_label:
		title_label.text = page.page_title
	if desc_label:
		desc_label.text = page.page_desc

	if page.page_image != null:
		if texture_rect:
			texture_rect.texture = page.page_image
			texture_rect.visible = true
	else:
		if texture_rect:
			texture_rect.visible = false

	if page_indicator:
		page_indicator.text = "%d / %d" % [index + 1, data.pages.size()]

func _update_buttons() -> void:
	var is_last := _current_page == data.pages.size() - 1

	if back_button:
		back_button.disabled = _current_page == 0
	if next_button:
		next_button.visible = not is_last
	if done_button:
		done_button.visible = is_last

func _on_next_button_pressed() -> void:
	if _current_page < data.pages.size() - 1:
		_current_page += 1
		_show_page(_current_page)
		_update_buttons()

func _on_back_button_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_show_page(_current_page)
		_update_buttons()

func _on_close_button_pressed() -> void:
	_close()

func _on_done_button_pressed() -> void:
	_close()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	emit_signal("closed")
	queue_free()
