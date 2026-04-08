# main-menu.gd
extends Control

@export var text: String = "Magis "
@export var font: Font
@export var font_size: int = 50
@export var scroll_speed: float = 80.0
@export var font_color: Color = Color(0.318, 0.323, 0.869, 0.1)
@export var line_spacing: int = 60
@export var row_offset: float = 0.5  # multiplier: 0.5 = half-row stagger between LTR/RTL
@export var start_y_offset: float = 0.5  # multiplier of line_spacing for first row Y

var _offset: float = 0.0

func _ready() -> void:
	if not font:
		font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	_offset += scroll_speed * delta
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if _offset >= text_width:
		_offset = 0.0
	queue_redraw()

func _draw() -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var row := 0
	var y := line_spacing * start_y_offset

	while y < size.y + font_size:
		var goes_right := row % 2 == 0

		if goes_right:
			var start_x := -text_width + fmod(_offset, text_width)
			var x := start_x
			while x < size.x + text_width:
				draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)
				x += text_width
		else:
			var start_x := size.x - fmod(_offset, text_width)
			var x := start_x
			while x > -text_width:
				draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)
				x -= text_width
 
		y += line_spacing
		row += 1

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/load-menu.tscn")
	

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/intro-menus/new-game-menu.tscn")

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/settings-menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
