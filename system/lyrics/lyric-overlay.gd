# lyrics-overlay.gd
# Attach to the CanvasLayer root of your LyricsOverlay scene.
extends CanvasLayer

@onready var _label: RichTextLabel = $Anchor/LyricLabel

const HOLD_TIME := 3.5
const FADE_TIME := 0.4

var _tween: Tween = null
var _enabled: bool = true


func _ready() -> void:
	print("[LyricsOverlay] _ready called")
	print("[LyricsOverlay] Label node found: ", is_instance_valid(_label))

	_enabled = _get_lyrics_setting()
	print("[LyricsOverlay] Lyrics enabled: ", _enabled)

	_label.modulate.a = 0.0
	_label.text = ""

	if not LyricsManager.lyric_changed.is_connected(_on_lyric_changed):
		LyricsManager.lyric_changed.connect(_on_lyric_changed)
		print("[LyricsOverlay] Connected to LyricsManager.lyric_changed")
	else:
		print("[LyricsOverlay] Already connected to lyric_changed")

	if not LyricsManager.lyrics_stopped.is_connected(_on_lyrics_stopped):
		LyricsManager.lyrics_stopped.connect(_on_lyrics_stopped)


func _on_lyric_changed(text: String) -> void:
	print("[LyricsOverlay] _on_lyric_changed received: '%s' | enabled: %s" % [text, _enabled])

	if not _enabled:
		print("[LyricsOverlay] Lyrics disabled — skipping display")
		return

	if _tween:
		_tween.kill()
	_tween = create_tween()

	if text.is_empty():
		_tween.tween_property(_label, "modulate:a", 0.0, FADE_TIME)
		return

	_label.text = "[center]%s[/center]" % text
	_tween.tween_property(_label, "modulate:a", 1.0, 0.15)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_TIME)


func _on_lyrics_stopped() -> void:
	print("[LyricsOverlay] lyrics_stopped received")
	if _tween:
		_tween.kill()
	_label.modulate.a = 0.0
	_label.text = ""


func set_enabled(value: bool) -> void:
	_enabled = value
	print("[LyricsOverlay] set_enabled: ", value)
	if not _enabled:
		_label.modulate.a = 0.0
		_label.text = ""


func _get_lyrics_setting() -> bool:
	# TEMP: force true so lyrics always show during testing
	# Replace with your config read once confirmed working:
	# var config := ConfigFile.new()
	# if config.load("user://settings.cfg") == OK:
	#     return config.get_value("accessibility", "show_lyrics", false)
	return true
