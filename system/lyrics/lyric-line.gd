# lyric-line.gd
class_name LyricLine

var time_sec: float
var text: String

func _init(t: float, s: String) -> void:
	time_sec = t
	text = s

func _to_string() -> String:
	return "[%.2fs] '%s'" % [time_sec, text]
