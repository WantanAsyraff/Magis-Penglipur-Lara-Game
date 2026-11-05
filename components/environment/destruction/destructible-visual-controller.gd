@tool
class_name DestructibleVisualController extends Node2D
## Art is independent of collision. Native placeholders stay replaceable in the Inspector.
enum Shape { CRATE, GLASS, STONE, PLATFORM, BARREL, CANISTER, FRAGMENTS, POD }
@export var placeholder_shape: Shape = Shape.CRATE
@export var placeholder_size := Vector2(64, 64)
@export var placeholder_color := Color("b98b53")
@export var fallback_texture: Texture2D
@export var fallback_frames: SpriteFrames
@export var animation_hooks: Dictionary[StringName, StringName] = {&"idle": &"idle", &"hit": &"hit", &"damaged": &"damaged", &"critical": &"critical", &"destroy_start": &"destroy_start", &"destroy_loop": &"destroy_loop", &"destroy_end": &"destroy_end", &"destroyed": &"destroyed", &"repair": &"repair", &"reset": &"reset"}
var state: DestructibleStateDefinition
var broken := false
var breaking := false
var break_age := 0.0
var break_duration := 0.4
var hit_age := 1.0
var end_age := -1.0
var last_hook: StringName
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated: AnimatedSprite2D = $AnimatedSprite2D
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
func _ready() -> void:
	sprite.visible = false; animated.visible = false
func present(definition: DestructibleStateDefinition, dead: bool, restoring: bool = false) -> void:
	state = definition; broken = dead; breaking = false; break_age = 0; end_age = -1.0
	modulate = state.modulate_color if state else Color.WHITE
	position = state.visual_offset if state else Vector2.ZERO
	scale = state.visual_scale if state else Vector2.ONE
	sprite.texture = state.sprite_texture if state and state.sprite_texture else fallback_texture
	sprite.visible = sprite.texture != null
	var frames := state.sprite_frames if state and state.sprite_frames else fallback_frames
	animated.visible = frames != null
	if animated.visible: animated.sprite_frames = frames; sprite.visible = false
	if state and state.animation_name != &"": play_animation(state.animation_name)
	else: play_hook(&"destroyed" if dead else &"idle")
	if state and not restoring: feedback(state.transition_sound, state.transition_particles)
	queue_redraw()
func play_animation(animation: StringName) -> bool:
	if animations.has_animation(animation): animations.stop(); animations.play(animation); return true
	if animated.visible and animated.sprite_frames and animated.sprite_frames.has_animation(animation): animated.stop(); animated.play(animation); return true
	if animated.visible and animated.sprite_frames.has_animation(&"idle"): animated.play(&"idle")
	elif animations.has_animation(&"idle"): animations.play(&"idle")
	return false
func play_hook(hook: StringName) -> bool:
	last_hook = hook
	if hook == &"hit": hit_age = 0.0
	return play_animation(animation_hooks.get(hook, hook))
func begin_destruction(duration: float) -> void:
	breaking = true; break_age = 0.0; break_duration = duration
	play_hook(&"destroy_start")
func finish_destruction() -> void:
	breaking = false; broken = true
	end_age = 0.0
	play_hook(&"destroy_end")
	queue_redraw()
func feedback(sound: AudioStream, particles: PackedScene) -> void:
	if sound: audio.stream = sound; audio.play()
	if particles and not Engine.is_editor_hint() and get_child_count() < 20:
		var effect := particles.instantiate()
		if not effect is Node2D: effect.free(); return
		add_child(effect)
		if effect is CPUParticles2D or effect is GPUParticles2D: effect.emitting = true
		var timer := Timer.new(); timer.one_shot = true; timer.wait_time = 4.0; effect.add_child(timer); timer.timeout.connect(effect.queue_free); timer.start()
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): queue_redraw(); return
	if end_age >= 0:
		end_age += delta
		if end_age >= 0.25: end_age = -1.0; play_hook(&"destroyed")
	hit_age += delta
	if breaking:
		break_age += delta
		if break_age > break_duration * 0.25 and last_hook == &"destroy_start": play_hook(&"destroy_loop")
	if breaking or hit_age < 0.2: queue_redraw()
func _draw() -> void:
	if is_instance_valid(sprite) and (sprite.visible or animated.visible): return
	var rect := Rect2(-placeholder_size / 2, placeholder_size)
	var color := placeholder_color
	if hit_age < 0.15: color = color.lightened(0.4)
	if broken and not breaking:
		draw_rect(Rect2(Vector2(-placeholder_size.x / 2, placeholder_size.y / 2 - 8), Vector2(placeholder_size.x, 8)), color.darkened(0.25))
		return
	if breaking:
		var progress := clampf(break_age / break_duration, 0, 1)
		for i in 6:
			var direction := Vector2.from_angle(i * TAU / 6)
			var piece_size := Vector2(placeholder_size.x / 3, placeholder_size.y / 2) * 0.8
			var origin := Vector2(-placeholder_size.x / 2 + (i % 3 + 0.5) * placeholder_size.x / 3, -placeholder_size.y / 2 + (floori(i / 3.0) + 0.5) * placeholder_size.y / 2)
			draw_rect(Rect2(origin + direction * progress * 80 - piece_size / 2, piece_size * (1 - progress * 0.3)), Color(color.lightened(0.25), 1 - progress))
		return
	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.35), false, 2.0)
	match placeholder_shape:
		Shape.CRATE:
			draw_line(rect.position, rect.end, color.darkened(0.5), 5)
			draw_line(Vector2(rect.end.x,rect.position.y),Vector2(rect.position.x,rect.end.y),color.darkened(0.5),5)
		Shape.GLASS: draw_line(rect.position + Vector2(8, 8), rect.end - Vector2(8, 8), Color.WHITE, 2)
		Shape.STONE: draw_line(Vector2(-20,0),Vector2(24,-12),color.darkened(.5),3)
		Shape.PLATFORM: draw_line(Vector2(-placeholder_size.x/2,0),Vector2(placeholder_size.x/2,0),color.darkened(.5),3)
		Shape.BARREL, Shape.CANISTER, Shape.FRAGMENTS:
			draw_circle(Vector2.ZERO, 16, Color("172331")); draw_arc(Vector2.ZERO,12,0,TAU,24,Color("ffd28c"),2)
			draw_line(Vector2(-placeholder_size.x/2,-20),Vector2(placeholder_size.x/2,-20),color.darkened(.5),5)
			draw_line(Vector2(-placeholder_size.x/2,20),Vector2(placeholder_size.x/2,20),color.darkened(.5),5)
		Shape.POD: draw_circle(Vector2.ZERO,20,Color("a8ebc1")); draw_arc(Vector2.ZERO,26,0,TAU,24,Color("244a3e"),4)
	if state and state.state_id in [&"damaged", &"critical"]:
		draw_polyline(PackedVector2Array([Vector2(-12,-placeholder_size.y/2),Vector2(3,-6),Vector2(-8,8),Vector2(14,placeholder_size.y/2)]),Color("182330"),3)
