# lrc-parser.gd
class_name LRCParser

static func parse(path: String) -> Array[LyricLine]:
	var lines: Array[LyricLine] = []

	print("[LRCParser] Attempting to open: ", path)

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[LRCParser] FAILED to open file: '%s' — error code: %s" % [path, FileAccess.get_open_error()])
		return lines

	print("[LRCParser] File opened OK")

	var regex := RegEx.new()
	regex.compile(r"^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)")

	var line_num := 0
	var parsed_count := 0

	while not file.eof_reached():
		var raw := file.get_line()
		line_num += 1
		var stripped := raw.strip_edges()

		if stripped.is_empty():
			continue

		# Skip comment lines
		if stripped.begins_with("#"):
			continue

		var m := regex.search(stripped)
		if not m:
			print("[LRCParser] Line %d skipped (no timestamp match): '%s'" % [line_num, stripped])
			continue

		var minutes := m.get_string(1).to_float()
		var seconds := m.get_string(2).to_float()
		var frac_str := m.get_string(3)
		var frac := frac_str.to_float() / pow(10.0, frac_str.length())
		var t := minutes * 60.0 + seconds + frac
		var text := m.get_string(4).strip_edges()

		var lyric := LyricLine.new(t, text)
		lines.append(lyric)
		parsed_count += 1
		print("[LRCParser] Parsed line %d: %s" % [line_num, lyric])

	lines.sort_custom(func(a: LyricLine, b: LyricLine) -> bool:
		return a.time_sec < b.time_sec
	)

	print("[LRCParser] Done. Total lines parsed: %d" % parsed_count)
	return lines
