# lyrics-manager.gd
# Autoload as: LyricsManager
extends Node

signal lyric_changed(text: String)
signal lyrics_stopped

var _lines: Array[LyricLine] = []
var _index: int = 0
var _player: AudioStreamPlayer = null
var _active: bool = false


func load_for_player(audio_player: AudioStreamPlayer, lrc_path: String) -> void:
	print("[LyricsManager] load_for_player called")
	print("[LyricsManager] Player valid: ", is_instance_valid(audio_player))
	print("[LyricsManager] LRC path: ", lrc_path)

	_player = audio_player
	_lines = LRCParser.parse(lrc_path)
	_index = 0
	_active = _lines.size() > 0

	print("[LyricsManager] Loaded %d lyric lines. Active: %s" % [_lines.size(), _active])

	if not _active:
		push_warning("[LyricsManager] No lines loaded — lyrics will not display.")


func stop() -> void:
	print("[LyricsManager] stop() called")
	_active = false
	_player = null
	_lines.clear()
	_index = 0
	lyrics_stopped.emit()


func _process(_delta: float) -> void:
	if not _active:
		return
	if not is_instance_valid(_player):
		push_warning("[LyricsManager] Player became invalid — stopping.")
		stop()
		return
	if not _player.playing:
		return
	if _index >= _lines.size():
		return

	var pos: float = _player.get_playback_position()
	var next: LyricLine = _lines[_index]

	if pos >= next.time_sec:
		print("[LyricsManager] Emitting lyric at %.2fs: '%s'" % [pos, next.text])
		lyric_changed.emit(next.text)
		_index += 1
