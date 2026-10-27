extends Node2D
const NPC = preload("res://components/NPCs/quest-npcs/flac/ariff-npc.tscn")
const MONSTER = preload("res://components/NPCs/enemies/zalam-manifestations/fishes/snakehead-murrel.tscn")
var checks := 0
var failures := 0
var box: Node2D
var player: CharacterBody2D
var npc: CharacterBody2D
var policy: NPCSpawnValidator
var manager: RoomQuestManager
var app: QuestUI
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func reset() -> void:
	QuestManager.persistence_enabled = false
	QuestManager._save_timer.stop()
	QuestManager._active_instances.clear()
	QuestManager.conversations = QuestConversationStore.new()
	QuestManager.live_offers.clear()
	QuestManager.offer_cooldowns.clear()
	QuestManager.seen_events.clear()
	QuestManager.reward_claims.clear()
	Player_Global_Data.completed_quests.clear()
	Inventory_Manager.reset()
	Player_Global_Data.p_moveable = true
func solid(center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size/2, Vector2(size.x/2,-size.y/2),size/2,Vector2(-size.x/2,size.y/2)])
	visual.color = color
	body.add_child(visual)
	box.add_child(body)
	return body
func _ready() -> void:
	await frames()
	reset()
	await run()
	if "--capture-quest-ui" in OS.get_cmdline_user_args(): await captures()
	print("QUEST_ACCESSIBILITY: %d checks, %d failures" % [checks, failures])
	QuestManager.persistence_enabled = false
	QuestManager._save_timer.stop()
	get_tree().quit(1 if failures else 0)
func run() -> void:
	box = Node2D.new()
	add_child(box)
	solid(Vector2(0,340),Vector2(1800,40),Color("527168"))
	solid(Vector2(0,260),Vector2(200,120),Color("916f58"))
	policy = NPCSpawnValidator.new()
	policy.allowed_region = Rect2(-850,-100,1700,600)
	policy.max_attempts = 4
	policy.minimum_separation = 240
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	check(not policy.valid(space,Vector2(0,200),policy.allowed_region),"Furniture blocks NPC body and interaction clearance")
	check(not policy.valid(space,Vector2(1000,200),policy.allowed_region),"NPC center/body must remain in allowed region")
	check(not policy.valid(space,Vector2(800,0),policy.allowed_region),"Floating NPC position rejected")
	var markers: Array[Vector2] = [Vector2(-500,300),Vector2(500,300)]
	var access: Array[Vector2] = [Vector2(-700,300),Vector2(700,300)]
	var placement := policy.choose(space,Vector2.ZERO,markers,access,[])
	check(not placement.is_empty() and placement.position.x == -500 and policy.valid(space,placement.position,policy.allowed_region),"Authored marker chooses grounded clear approachable NPC position")
	var blocked: Array[Vector2] = [placement.position]
	var second := policy.choose(space,Vector2.ZERO,markers,access,blocked)
	check(not second.is_empty() and second.position.distance_to(placement.position)>=240,"Placement respects minimum NPC separation")
	var impossible := policy.duplicate() as NPCSpawnValidator
	impossible.allowed_region = Rect2(0,0,1,1)
	impossible.fallback_enabled = true
	impossible.fallback_feet = Vector2(0,260)
	check(impossible.choose(space,Vector2.ZERO,markers,access,[]).is_empty(),"No safe placement terminates, rejecting blocked fallback")
	var fallback := policy.duplicate() as NPCSpawnValidator
	fallback.max_attempts = 0
	fallback.fallback_enabled = true
	fallback.fallback_feet = Vector2(500,300)
	check(not fallback.choose(space,Vector2.ZERO,[],access,[]).is_empty(),"Explicit safe fallback still validates ground and access")
	check(not policy.reachable(space,Vector2(-500,200),Vector2(500,200)),"Furniture wall cannot be crossed by approach validation")
	npc = NPC.instantiate()
	npc.position = placement.position
	box.add_child(npc)
	npc.dialogic.use_dialogic = false
	npc.wander.validator = policy
	npc.wander.region = policy.allowed_region
	npc.wander.set_origin(npc.position)
	player = CharacterBody2D.new()
	player.add_to_group("player")
	player.position = Vector2(-650,200)
	box.add_child(player)
	await frames()
	check(npc.quest.presentation.portrait == NPCPresentation.resolve("flac_ariff_npc").portrait,"NPC identity resolves the same Ariff portrait used by Dialogic")
	check(DetectionComponent.focused(get_tree()) == npc.detection,"Eligible nearby NPC receives predictable interaction focus")
	player.position = Vector2(-350,200)
	check(npc.detection.available(player),"Interaction works from opposite accessible side")
	player.position = Vector2(150,200)
	npc.detection.interaction_radius = 800
	check(not npc.detection.available(player),"Visible quest marker does not permit interaction through furniture")
	npc.detection.interaction_radius = 250
	player.position = Vector2(-650,200)
	var rival_a := CharacterBody2D.new()
	rival_a.name = "FocusA"
	rival_a.position = player.position + Vector2(80,0)
	var detect_a := DetectionComponent.new()
	rival_a.add_child(detect_a)
	box.add_child(rival_a)
	var rival_b := CharacterBody2D.new()
	rival_b.name = "FocusB"
	rival_b.position = player.position - Vector2(80,0)
	var detect_b := DetectionComponent.new()
	rival_b.add_child(detect_b)
	box.add_child(rival_b)
	check(DetectionComponent.focused(get_tree()) == detect_a, "Overlapping NPC ranges choose nearest then stable path tie-break")
	rival_a.free()
	rival_b.free()
	var start := npc.position
	npc.wander._target_x = start.x + 60
	npc.wander._pause_timer = 0
	var displacement := 0.0
	var max_movement_step := 0.0
	var previous_x: float = npc.position.x
	for tick in 120:
		await get_tree().physics_frame
		displacement = maxf(displacement, absf(npc.position.x - start.x))
		max_movement_step = maxf(max_movement_step, absf(npc.position.x - previous_x))
		previous_x = npc.position.x
	check(policy.allowed_region.has_point(npc.position) and absf(npc.position.x-start.x)<=npc.wander.wander_range_x+5,"Real wandering stays in configured bounds")
	check(max_movement_step <= npc.wander.move_speed / Engine.physics_ticks_per_second + .2, "NPC controller applies at most one movement step per physics frame")
	check(displacement > 10,"Wandering remains enabled on valid floor")
	check(npc.quest.quest_indicator.z_index > npc.z_index,"Quest marker remains readable without raising whole NPC")
	npc.wander.stationary = true
	var instance: QuestInstance = npc.quest._instance
	npc.quest.confirm_offer_complete()
	check(instance.status == QuestInstance.Status.AVAILABLE,"Legacy dialogue callback cannot accept quests")
	npc.quest.interact()
	await frames()
	var panel := QuestOfferDialog.current
	check(panel != null and panel.instance == instance and panel.identity.npc_id == npc.quest.npc_id,"Actual NPC interaction opens correctly identified offer")
	check(not npc.detection.available(player),"Open offer blocks repeated world interaction")
	check(panel.body.get_child(0).text == instance.quest_data.title and not instance.quest_data.dialogue_offer.is_empty() and panel.body.get_child(1).text == instance.quest_data.dialogue_offer,"Offer uses authored title and dialogue")
	panel.decide("decline")
	panel.decide("decline")
	var contact: QuestConversation = QuestManager.conversations.contacts[npc.quest.npc_id]
	check(instance.status == QuestInstance.Status.AVAILABLE and not QuestManager.is_quest_complete(instance.quest_data.quest_id),"Decline leaves quest inactive and incomplete")
	check(contact.entries.filter(func(e): return e.event_type=="PLAYER_DECLINED").size()==1,"Repeated decline callback logs one decision")
	check(contact.entries.back().message_text==npc.quest.presentation.declined,"Decline logs configured NPC-specific reaction")
	check(Player_Global_Data.p_moveable,"Decline restores prior player input state")
	await frames()
	panel = QuestOfferDialog.show_offer(instance.instance_id,npc.quest.npc_id,npc.quest,npc.quest.presentation)
	check(panel != null,"Declined quest can be reoffered")
	panel.decide("dismiss")
	check(instance.status==QuestInstance.Status.AVAILABLE and contact.entries.back().event_type=="OFFER_DISMISSED","Closing without decision is distinct from decline")
	await frames()
	panel = QuestOfferDialog.show_offer(instance.instance_id,npc.quest.npc_id,npc.quest,npc.quest.presentation)
	var xp: float = Player_Global_Data.player_exp
	panel.decide("accept")
	panel.decide("accept")
	check(instance.status==QuestInstance.Status.ACTIVE and Player_Global_Data.player_exp==xp,"Explicit Accept activates once without granting rewards")
	check(contact.entries.filter(func(e): return e.event_type=="PLAYER_ACCEPTED").size()==1,"Acceptance logs once despite repeated button callback")
	await frames()
	var previous_instance := instance
	var npc_save := "user://quest-npc-restore-%d.json" % OS.get_process_id()
	check(QuestManager.save_game(npc_save) and QuestManager.load_game(npc_save) and npc.quest._instance != previous_instance and npc.quest._instance.instance_id == previous_instance.instance_id, "Live NPC reacquires restored authoritative quest instance")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(npc_save))
	instance = npc.quest._instance
	# Dismissal, pause, stale offer and source lifecycle do not accept.
	await frames()
	var temporary := Node.new()
	box.add_child(temporary)
	var other := QuestManager.offer_quest("defeat_tree_quest", "flac_ariff_npc")
	panel = QuestOfferDialog.show_offer(other.instance_id, "flac_ariff_npc", temporary)
	temporary.queue_free()
	await frames()
	check(not QuestOfferDialog.is_open() and other.status == QuestInstance.Status.AVAILABLE and Player_Global_Data.p_moveable, "Source despawn dismisses offer and restores input")
	npc.quest._instance = other
	npc.dialogic.use_dialogic = true
	npc.quest.interact()
	await frames()
	Dialogic.end_timeline()
	if npc.dialogic.is_open(): await npc.dialogic.dialogue_ended
	await frames()
	panel = QuestOfferDialog.current
	check(panel != null and other.status == QuestInstance.Status.AVAILABLE, "Natural Dialogic introduction completion presents a decision without accepting")
	panel.decide("decline")
	await frames()
	check(Dialogic.current_timeline != null and not panel.visible and not Player_Global_Data.p_moveable, "Actual NPC reaction uses visible Dialogic while native offer yields input")
	npc.dialogic.close()
	if npc.dialogic.is_open(): await npc.dialogic.dialogue_ended
	await frames()
	check(not QuestOfferDialog.is_open() and Player_Global_Data.p_moveable and other.status == QuestInstance.Status.AVAILABLE, "Closing reaction restores input without accepting declined quest")
	npc.dialogic.use_dialogic = false
	panel = QuestOfferDialog.show_offer(other.instance_id, "flac_ariff_npc", self)
	get_tree().paused = true
	await frames()
	get_tree().paused = false
	check(not QuestOfferDialog.is_open() and other.status == QuestInstance.Status.AVAILABLE, "Pause dismisses an unresolved offer without accepting")
	panel = QuestOfferDialog.show_offer(other.instance_id, "flac_ariff_npc", self)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await frames()
	check(not QuestOfferDialog.is_open() and other.status == QuestInstance.Status.AVAILABLE, "Escape dismisses through actual Godot input routing")
	var receipt := QuestManager.present_offer(other.instance_id, "flac_ariff_npc")
	other.owner_id = "other"
	check(not QuestManager.decide_offer(receipt, "accept"), "Offer owner tampering fails without activating")
	other.owner_id = "local"
	QuestManager.live_offers.clear()
	check(QuestManager.present_offer(other.instance_id, "flac_ariff_npc", NPCPresentation.resolve("flac_hasan_npc")).is_empty(), "Mismatched portrait identity is rejected")
	# Every shipped quest uses the same reusable card/decision path.
	for data in QuestManager.registry.quests.values():
		reset()
		Player_Global_Data.completed_quests.assign(data.prerequisite_quest_ids)
		var id: String = data.hand_in_npc_id if not data.hand_in_npc_id.is_empty() else "flac_ariff_npc"
		instance = QuestManager.offer_quest(data.quest_id,id)
		panel = QuestOfferDialog.show_offer(instance.instance_id,id,self)
		var reward_row := QuestWidgets.rewards(data)
		var icons_ok := true
		for i in data.reward_items.size():
			icons_ok = icons_ok and reward_row.get_child(i+1+(1 if data.reward_currency>0 else 0)).get_child(0).texture==data.reward_items[i].item.item_icon
		check(panel.body.get_child(0).text==data.title and QuestWidgets.objective_text(data).contains(data.objectives[0].description) and icons_ok,"Resource-driven portrait/objectives/reward icons: "+data.quest_id)
		reward_row.free()
		panel.decide("accept")
		check(instance.status in [QuestInstance.Status.ACTIVE,QuestInstance.Status.COMPLETE],"Explicit native offer accepts shipped quest: "+data.quest_id)
		await frames()
	# Chat contacts, alignment, progress, history and persistence.
	reset()
	instance = QuestManager.offer_quest("quest_bakau_001","bakau_field_researcher")
	var token := QuestManager.present_offer(instance.instance_id,"bakau_field_researcher")
	QuestManager.decide_offer(token,"decline")
	token = QuestManager.present_offer(instance.instance_id,"bakau_field_researcher")
	QuestManager.decide_offer(token,"accept")
	var extra := QuestManager.offer_quest("quest_bakau_003","bakau_field_researcher")
	QuestManager.decide_offer(QuestManager.present_offer(extra.instance_id,"bakau_field_researcher"),"decline")
	var canvas := CanvasLayer.new()
	add_child(canvas)
	app = load("res://scenes/ui/quest-ui/quest-ui.tscn").instantiate()
	app.size = Vector2(448,640)
	canvas.add_child(app)
	await frames()
	check(app.contact_rows.size()==1,"Multiple quests from one stable NPC share a conversation")
	var motion := InputEventMouseMotion.new()
	motion.position = app.contact_rows.bakau_field_researcher.get_global_rect().get_center()
	motion.global_position = motion.position
	get_viewport().push_input(motion, true)
	await frames()
	var click := InputEventMouseButton.new()
	click.position = app.contact_rows.bakau_field_researcher.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	get_viewport().push_input(click, true)
	await frames()
	click = click.duplicate()
	click.pressed = false
	get_viewport().push_input(click, true)
	await frames()
	check(app.selected_contact == "bakau_field_researcher", "Actual mouse input opens a contact through avatar and preview controls")
	check(app.rendered_bubbles.any(func(b): return b.get_meta("sender_type")=="player") and app.rendered_bubbles.any(func(b): return b.get_meta("sender_type")=="npc"),"Chat renders distinct player and NPC bubble alignment")
	var before: int = QuestManager.conversations.contacts.bakau_field_researcher.entries.size()
	for i in 3: defeat_fish()
	await frames()
	check(instance.objective_progress.values()[0]==3 and QuestWidgets.objective_text(instance.quest_data,instance).contains("3 / 8"),"Actual enemy deaths update live chat objective card")
	check(QuestManager.conversations.contacts.bakau_field_researcher.entries.size()==before,"Per-kill progress does not flood conversation bubbles")
	for i in 5: defeat_fish()
	QuestManager.try_hand_off(instance.instance_id,"bakau_field_researcher")
	await frames()
	contact=QuestManager.conversations.contacts.bakau_field_researcher
	check(contact.entries.any(func(e): return e.event_type=="QUEST_COMPLETED") and contact.entries.any(func(e): return e.event_type=="REWARD_CLAIMED"),"Completed history and reward receipt remain visible")
	check(app.quest_cards.has("quest_bakau_001") and app.quest_cards.has("quest_bakau_003"),"Chat retains identifiable cards for multiple quests")
	QuestManager.save_path="user://quest-accessibility-regression-%d.json" % OS.get_process_id()
	var count := contact.entries.size()
	check(QuestManager.save_game() and QuestManager.load_game() and QuestManager.load_game(),"Conversation snapshot saves and loads repeatedly")
	check(QuestManager.conversations.contacts.bakau_field_researcher.entries.size()==count,"Repeated restore replaces logs without duplicating messages")
	check(not QuestManager.conversations.contacts.bakau_field_researcher.unread(),"Read/unread state survives restore")
	app._back()
	check(app.selected_contact.is_empty(),"Chat Back returns to contact list")
	canvas.free()
	# Actual phone embedding must not change scene/player coordinates.
	var phone: Control = load("res://scenes/ui/phone-ui/phone-ui.tscn").instantiate()
	Player_Global_Data.phone_visible=true
	add_child(phone)
	var original_scene := get_tree().current_scene
	phone._on_app_opened(load("res://scenes/ui/quest-ui/quest-ui.tscn"))
	check(phone.current_app_node is QuestUI and get_tree().current_scene==original_scene,"Phone opens messages inline without scene transition")
	phone.current_app_node._back()
	check(phone.current_app_node==null,"Phone app Back restores app launcher")
	phone.free()
	var talking: CharacterBody2D = load("res://components/NPCs/basic-npcs/talking-npc.tscn").instantiate()
	talking.position = Vector2(-700,200)
	box.add_child(talking)
	var active_count: int = QuestManager.get_all_active().size()
	talking._on_interacted()
	await frames()
	check(talking.dialogic.is_open() and talking.quest == null, "Existing nonquest NPC starts its configured greeting through normal interaction")
	Dialogic.end_timeline()
	if talking.dialogic.is_open(): await talking.dialogic.dialogue_ended
	await frames()
	check(Player_Global_Data.p_moveable and QuestManager.get_all_active().size() == active_count and get_tree().current_scene == original_scene, "Nonquest dialogue restores input without accepting quests or changing scene")
	talking.free()
	# Real FLAC geometry and authored policies, including wandering.
	for i in range(1,4):
		var room: Node = load("res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-two/FLAC-F2-hallway-room-"+str(i)+".tscn").instantiate()
		room._player_setup_done=true
		add_child(room)
		for tick in 6: await get_tree().physics_frame
		var spawner: RoomQuestManager=room.find_child("NpcQuestSpawner",true,false)
		check(spawner.active_npcs.size()==spawner.npcs_to_spawn,"Actual FLAC room has safely placed configured NPC count: "+str(i))
		var valid := true
		for placed in spawner.active_npcs:
			var exclusions: Array[RID]=[placed.get_rid()]
			valid=valid and spawner.spawn_validator.valid(space,placed.global_position,Rect2(spawner.global_position+spawner.spawn_validator.allowed_region.position,spawner.spawn_validator.allowed_region.size),[],exclusions)
		check(valid,"Actual room NPC bodies and approach lanes validate: "+str(i))
		var associations := true
		for placed in spawner.active_npcs:
			if placed.quest._instance: associations = associations and placed.quest._instance.assigned_npc_id == placed.quest.npc_id
		check(associations, "Actual room offers remain associated with their own NPC identity: " + str(i))
		room.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(QuestManager.save_path))
func defeat_fish() -> void:
	var enemy: Enemy = MONSTER.instantiate()
	enemy.position=Vector2(4000,0)
	box.add_child(enemy)
	enemy.hitbox.receive_damage(100000,player)
func shot(filename: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/magis-quest-accessibility/"+filename+".png")
func captures() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/magis-quest-accessibility")
	reset()
	box.hide()
	var room: Node = load("res://scenes/worlds/hubs/akademi-bintang-utama(ABU)/faculty-of-logic-and-computation(FLAC)/floor-two/FLAC-F2-hallway-room-1.tscn").instantiate()
	room._player_setup_done = true
	var spawner: RoomQuestManager = room.find_child("NpcQuestSpawner", true, false)
	spawner.npcs_to_spawn = 1
	var single: Dictionary[String, PackedScene] = {"flac_ariff_npc": NPC}
	spawner.npc_directory = single
	add_child(room)
	var camera := Camera2D.new()
	camera.position = Vector2(-1350,650)
	camera.zoom = Vector2(1.5,1.5)
	add_child(camera)
	camera.make_current()
	for tick in 12: await get_tree().physics_frame
	var actual: CharacterBody2D = spawner.active_npcs[0]
	actual.wander.stationary = true
	actual.dialogic.use_dialogic = false
	player.global_position = actual.global_position + Vector2(-150,0)
	await shot("01-flac-accessible-npc")
	actual.quest.interact()
	await shot("02-portrait-offer-objectives-rewards-actions")
	QuestOfferDialog.current.decide("decline")
	await frames()
	var sub := SubViewport.new()
	sub.size = Vector2i(448,640)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	var messages: QuestUI = load("res://scenes/ui/quest-ui/quest-ui.tscn").instantiate()
	sub.add_child(messages)
	messages._select("flac_ariff_npc")
	await shot_app(sub,"03-declined-conversation")
	room.free()
	camera.free()
	reset()
	box.show()
	var instance := QuestManager.offer_quest("quest_bakau_001","bakau_field_researcher")
	var receipt := QuestManager.present_offer(instance.instance_id,"bakau_field_researcher")
	QuestManager.decide_offer(receipt,"accept")
	messages.selected_contact=""
	messages._refresh()
	await shot_app(sub,"04-quest-contact-list")
	messages._select("bakau_field_researcher")
	await shot_app(sub,"05-accepted-conversation")
	for i in 3: defeat_fish()
	await shot_app(sub,"06-live-progress-conversation")
	for i in 5: defeat_fish()
	QuestManager.try_hand_off(instance.instance_id,"bakau_field_researcher")
	await shot_app(sub,"07-completed-reward-conversation")
	sub.free()
	var phone: Control = load("res://scenes/ui/phone-ui/phone-ui.tscn").instantiate()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	Player_Global_Data.phone_visible=true
	canvas.add_child(phone)
	phone.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	phone.position=Vector2(600,100)
	phone.phone_selected=true
	phone._on_app_opened(load("res://scenes/ui/quest-ui/quest-ui.tscn"))
	await shot("08-embedded-phone-app")
	canvas.free()
func shot_app(sub: SubViewport, filename: String) -> void:
	await frames()
	await frames()
	await RenderingServer.frame_post_draw
	sub.get_texture().get_image().save_png("/tmp/magis-quest-accessibility/"+filename+".png")
