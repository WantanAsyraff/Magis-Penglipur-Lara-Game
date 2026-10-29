class_name InteractionVisual extends Node2D
var data: EnvironmentVisualData
var device: EnvironmentDeviceData
var active := false
var state: StringName = &"inactive"
var level := 0.0
var angle := 0.0
var _configured := false
var _art: Node2D
var _audio: AudioStreamPlayer2D
func configure(config: EnvironmentDeviceData) -> void:
	device = config
	data = config.visual if config.visual else EnvironmentVisualData.new()
	position = data.offset
	scale = data.scale
	if data.visual_scene:
		var art := data.visual_scene.instantiate()
		if art is Node2D: _art = art; add_child(art)
		else: art.free(); push_warning("Custom visual root must be Node2D; using procedural fallback")
	elif data.frames:
		var sprite := AnimatedSprite2D.new(); sprite.sprite_frames = data.frames; _art = sprite; add_child(sprite)
	elif data.texture:
		var sprite := Sprite2D.new(); sprite.texture = data.texture; _art = sprite; add_child(sprite)
	_audio = AudioStreamPlayer2D.new(); add_child(_audio)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	present(false)
func present(value: bool, override_state: StringName = &"") -> void:
	var next_state: StringName = override_state if override_state != &"" else (&"active" if value else &"inactive")
	if _configured and active == value and state == next_state: queue_redraw(); return
	_configured = true
	var was := active
	active = value
	state = next_state
	var animation: StringName = data.active_animation if active else data.idle_animation
	if state == &"broken": animation = data.broken_animation
	if _art is AnimatedSprite2D:
		if not _art.sprite_frames.has_animation(animation): animation = data.idle_animation
		if _art.sprite_frames.has_animation(animation): _art.play(animation)
	if _art:
		var animator := _art.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if animator and animator.has_animation(animation): animator.play(animation)
	if was != active and is_inside_tree():
		_audio.stream = data.activate_sound if active else data.deactivate_sound
		if _audio.stream: _audio.play()
		if active and data.particles:
			var effect := data.particles.instantiate(); add_child(effect)
			if effect is GPUParticles2D or effect is CPUParticles2D:
				effect.one_shot = true; effect.emitting = true; effect.finished.connect(effect.queue_free)
	queue_redraw()
func _draw() -> void:
	if device == null or _art != null: return
	var size := device.size
	var rect := Rect2(-size/2,size)
	var tint := data.tint if active else data.tint.darkened(.65)
	if state == &"broken": tint = Color(.36,.27,.24)
	elif state == &"damaged": tint = Color(.8,.5,.26)
	elif state == &"warning": tint = Color(1,.4,.2)
	draw_rect(rect,Color(.06,.09,.12,.96))
	draw_rect(rect,tint,false,3)
	match device.kind:
		EnvironmentDeviceData.Kind.SWITCH,EnvironmentDeviceData.Kind.FUSE,EnvironmentDeviceData.Kind.LEVER:
			draw_line(Vector2(0,18),Vector2(15 if active else -15,-18),tint,8,true)
		EnvironmentDeviceData.Kind.LIGHT:
			draw_circle(Vector2.ZERO,minf(size.x,size.y)*.3,tint)
		EnvironmentDeviceData.Kind.GATE:
			for x in [-.35,-.1,.15,.4]: draw_line(Vector2(size.x*x+(size.x if active else 0),-size.y/2),Vector2(size.x*x+(size.x if active else 0),size.y/2),tint,4)
			if active: draw_line(-size/2,size/2,Color(.5,1,.7),4)
		EnvironmentDeviceData.Kind.TANK,EnvironmentDeviceData.Kind.DRAIN:
			draw_rect(Rect2(Vector2(-size.x/2+4,size.y/2-(size.y-8)*level),Vector2(size.x-8,(size.y-8)*level)),Color(.2,.6,.9,.7))
			if device.kind == EnvironmentDeviceData.Kind.DRAIN: draw_line(Vector2(-20,0),Vector2(20,0),tint,4)
		EnvironmentDeviceData.Kind.VALVE:
			draw_arc(Vector2.ZERO,24,0,TAU,24,tint,4,true)
			draw_line(Vector2(-20,0).rotated(angle),Vector2(20,0).rotated(angle),tint,5)
			if active:
				for x in [-10,0,10]: draw_line(Vector2(x,30),Vector2(x+sin(angle)*3,60),Color(.3,.7,1,.8),3)
		EnvironmentDeviceData.Kind.FAN:
			for i in 4: draw_line(Vector2.ZERO,Vector2(0,-size.x*.42).rotated(angle+i*TAU/4),tint,10,true)
			draw_circle(Vector2.ZERO,8,Color(.8,.85,.9))
		EnvironmentDeviceData.Kind.RECEIVER:
			draw_arc(Vector2.ZERO,25,0,TAU,30,tint,4,true); draw_line(Vector2(-16,0),Vector2(16,0),tint,4)
		EnvironmentDeviceData.Kind.PLATE:
			draw_rect(Rect2(-size/2,Vector2(size.x,size.y*.4)),tint)
		EnvironmentDeviceData.Kind.TURRET:
			draw_circle(Vector2.ZERO,25,tint); draw_line(Vector2.ZERO,Vector2(45,0).rotated(angle),tint,10)
		EnvironmentDeviceData.Kind.BREAKABLE:
			draw_line(-size/2,size/2,tint,4); draw_line(Vector2(-size.x/2,size.y/2),Vector2(size.x/2,-size.y/2),tint,4)
		EnvironmentDeviceData.Kind.PUMP,EnvironmentDeviceData.Kind.RELAY:
			draw_circle(Vector2.ZERO,18,tint,false,4,true); draw_line(Vector2(-size.x/2,0),Vector2(size.x/2,0),tint,3)
