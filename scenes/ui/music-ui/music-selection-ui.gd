extends PhoneAppPage
@export var tracks: Array[AudioStream] = [preload("res://assets/audio/music/aku-skandal.mp3")]
@export var track_titles: PackedStringArray = ["Skandal"]
@export var track_artists: PackedStringArray = ["Hujan"]
var audio: AudioStreamPlayer
var current_index := 0
var play_button: Button
var previous_button: Button
var next_button: Button
var seek: HSlider
var volume: HSlider
var elapsed_label: Label
var duration_label: Label
var title_label: Label
var artist_label: Label
var state_label: Label
var library: VBoxContainer
var record: RecordArt
class RecordArt extends Control:
	var playing := false
	var angle := 0.0
	func _process(delta: float) -> void:
		if playing: angle += delta*.35; queue_redraw()
	func _draw() -> void:
		var center := size*.5; var radius := minf(size.x,size.y)*.47
		draw_circle(center,radius,Color("101e27"))
		for ratio in [.95,.84,.72,.6]: draw_arc(center,radius*ratio,0,TAU,80,Color("3c5661"),1,true)
		draw_circle(center,radius*.3,Color("b4cfb3")); draw_circle(center,radius*.055,Color("1d3039"))
		draw_line(center+Vector2.from_angle(angle)*radius*.36,center+Vector2.from_angle(angle)*radius*.85,Color("71918e"),2,true)
func _ready() -> void:
	build_page("Music","MAGIS / PERSONAL COLLECTION","A little soundtrack for the journey.")
	var world := get_tree().current_scene
	if world == null: world = self
	audio = world.get_node_or_null("PhoneMusicPlayer") as AudioStreamPlayer
	if audio == null:
		audio = AudioStreamPlayer.new(); audio.name = "PhoneMusicPlayer"; audio.process_mode = Node.PROCESS_MODE_ALWAYS; audio.volume_db = linear_to_db(.45); world.add_child(audio)
	audio.finished.connect(_on_track_finished)
	for i in tracks.size():
		if tracks[i] != null and tracks[i] == audio.stream: current_index = i; break
	var library_panel := card(); library_panel.custom_minimum_size.x = 285; page_body.add_child(library_panel)
	var library_body := column(18); library_panel.add_child(library_body)
	library_body.add_child(text("Your library",22)); library_body.add_child(text("%d track%s" % [tracks.size(),"" if tracks.size() == 1 else "s"],13,MUTED))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true; library_body.add_child(scroll)
	library = column(10); library.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(library)
	for i in tracks.size():
		var song := action("%02d   %s\n       %s" % [i+1,_title(i),_artist(i)],_select.bind(i)); song.alignment = HORIZONTAL_ALIGNMENT_LEFT; song.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; song.toggle_mode = true; song.custom_minimum_size.y = 80; library.add_child(song)
	if tracks.is_empty(): library.add_child(text("No tracks in your library.",14,MUTED))
	var right := column(16); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; page_body.add_child(right)
	var now := card(NAVY); now.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(now)
	var now_body := column(8); now.add_child(now_body)
	state_label = text("READY TO PLAY",12,Color("b5d9ce")); now_body.add_child(state_label)
	record = RecordArt.new(); record.custom_minimum_size.y = 160; record.size_flags_vertical = Control.SIZE_EXPAND_FILL; now_body.add_child(record)
	title_label = text("",30,Color.WHITE); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title_label.max_lines_visible = 2; title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; now_body.add_child(title_label)
	artist_label = text("",16,Color("c6d5d7")); artist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; artist_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; artist_label.max_lines_visible = 2; now_body.add_child(artist_label)
	var controls := card(); right.add_child(controls); var control_body := column(9); controls.add_child(control_body)
	seek = HSlider.new(); seek.step = .1; seek.custom_minimum_size.y = 14; control_body.add_child(seek); seek.value_changed.connect(_seek)
	var times := HBoxContainer.new(); control_body.add_child(times); elapsed_label = text("0:00",13,MUTED); elapsed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; times.add_child(elapsed_label); duration_label = text("0:00",13,MUTED); times.add_child(duration_label)
	var transport := HBoxContainer.new(); transport.alignment = BoxContainer.ALIGNMENT_CENTER; transport.add_theme_constant_override("separation",12); control_body.add_child(transport)
	previous_button = action("Previous",_change.bind(-1)); transport.add_child(previous_button)
	play_button = action("Play",_toggle_play); play_button.custom_minimum_size.x = 130; transport.add_child(play_button)
	next_button = action("Next",_change.bind(1)); transport.add_child(next_button)
	var volume_row := HBoxContainer.new(); volume_row.add_theme_constant_override("separation",14); control_body.add_child(volume_row); volume_row.add_child(text("Volume",13,MUTED))
	volume = HSlider.new(); volume.min_value = 0; volume.max_value = 1; volume.step = .01; volume.value = db_to_linear(audio.volume_db); volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL; volume.custom_minimum_size.x = 140; volume_row.add_child(volume)
	volume.value_changed.connect(func(value): audio.volume_db = linear_to_db(maxf(.0001,value)))
	_refresh_track()
func _title(index: int) -> String:
	if index < track_titles.size() and not track_titles[index].is_empty(): return track_titles[index]
	return tracks[index].resource_path.get_file().get_basename().replace("-"," ").capitalize() if tracks[index] else "Unavailable track"
func _artist(index: int) -> String:
	return track_artists[index] if index < track_artists.size() else ""
func _select(index: int) -> void:
	if index < 0 or index >= tracks.size() or tracks[index] == null: return
	var continue_playing := audio.playing and not audio.stream_paused
	current_index = index
	if audio.stream != tracks[index]:
		audio.stop(); audio.stream_paused = false; audio.remove_meta("phone_seek"); audio.stream = tracks[index]
		seek.set_value_no_signal(0)
		if continue_playing: audio.play()
	_refresh_track()
func _refresh_track() -> void:
	var available := current_index >= 0 and current_index < tracks.size() and tracks[current_index] != null
	if available:
		if audio.stream == null: audio.stream = tracks[current_index]
		title_label.text = _title(current_index); title_label.tooltip_text = title_label.text; artist_label.text = _artist(current_index); seek.max_value = maxf(1,tracks[current_index].get_length()); duration_label.text = _time(tracks[current_index].get_length())
	else: title_label.text = "Your soundtrack starts here"; artist_label.text = "No playable tracks"; duration_label.text = "0:00"
	seek.editable = available; play_button.disabled = not available; volume.editable = available
	previous_button.disabled = tracks.size() < 2; next_button.disabled = tracks.size() < 2
	for i in library.get_child_count():
		if library.get_child(i) is Button: library.get_child(i).set_pressed_no_signal(i == current_index)
	if audio.has_meta("phone_seek"): seek.set_value_no_signal(float(audio.get_meta("phone_seek")))
	elif audio.playing: seek.set_value_no_signal(audio.get_playback_position())
	_update_playback()
func _toggle_play() -> void:
	if current_index < 0 or current_index >= tracks.size() or tracks[current_index] == null: return
	if audio.stream != tracks[current_index]: audio.stop(); audio.stream = tracks[current_index]
	if audio.stream_paused:
		audio.stream_paused = false
		if audio.has_meta("phone_seek"):
			audio.play(float(audio.get_meta("phone_seek"))); audio.remove_meta("phone_seek")
	elif audio.playing: audio.stream_paused = true
	else:
		audio.play(seek.value); audio.remove_meta("phone_seek")
	_update_playback()
func _change(direction: int) -> void:
	if tracks.size() > 1: _select(posmod(current_index+direction,tracks.size()))
func _seek(value: float) -> void:
	if audio.playing and not audio.stream_paused: audio.seek(value)
	else: audio.set_meta("phone_seek",value)
	elapsed_label.text = _time(value)
func _process(_delta: float) -> void:
	if not is_instance_valid(audio) or play_button == null: return
	_update_playback()
	if audio.playing and not audio.stream_paused and not seek.has_focus(): seek.set_value_no_signal(audio.get_playback_position())
	elapsed_label.text = _time(audio.get_playback_position() if audio.playing and not audio.stream_paused else seek.value)
func _update_playback() -> void:
	var playing := audio.playing and not audio.stream_paused
	play_button.text = "Pause" if playing else "Play"
	state_label.text = "NOW PLAYING" if playing else ("PAUSED" if audio.stream_paused else "READY TO PLAY")
	record.playing = playing
func _time(seconds: float) -> String:
	var whole := maxi(0,int(seconds)); return "%d:%02d" % [whole/60,whole%60]

func _on_track_finished() -> void:
	audio.remove_meta("phone_seek")
	seek.set_value_no_signal(0)
	elapsed_label.text = "0:00"
	_update_playback()
