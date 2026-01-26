extends Control

@onready var open_id_line: LineEdit = %OpenIdLine
@onready var join_line: LineEdit = %JoinLine
@onready var relay_check: CheckBox = %RelayCheck
@onready var status_label: Label = %StatusLabel
@onready var peers_label: Label = %PeersLabel

@onready var host_button: Button = %HostButton
@onready var copy_button: Button = %CopyButton
@onready var join_button: Button = %JoinButton




func _ready() -> void:
	print("UI ready. Network_Manager is:", Network_Manager)

	# ✅ Hook up button presses
	host_button.pressed.connect(_on_host_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	join_button.pressed.connect(_on_join_pressed)

	# ✅ Connect signals ONCE
	Network_Manager.noray_ready.connect(_on_noray_ready)
	Network_Manager.connected_to_host.connect(func():
		_set_status("Connected to host ✅")
	)
	Network_Manager.connection_failed.connect(func(err: int):
		_set_status("Connection failed ❌ (err=%d)" % err)
	)
	Network_Manager.player_joined.connect(func(peer_id: int):
		_set_status("Peer joined: %d" % peer_id)
		_update_peers()
	)
	Network_Manager.player_left.connect(func(peer_id: int):
		_set_status("Peer left: %d" % peer_id)
		_update_peers()
	)

	_update_peers()

func _on_host_pressed() -> void:
	release_focus()
	get_viewport().gui_release_focus()
	print("[UI] Host button pressed")
	_set_status("Hosting... (connecting to Noray)")
	Network_Manager.host_game()

func _on_join_pressed() -> void:
	var code := join_line.text.strip_edges()
	if code == "":
		_set_status("Paste an OpenID first.")
		return

	_set_status("Joining... (connecting to Noray)")
	Network_Manager.join_game(code, relay_check.button_pressed)

func _on_copy_pressed() -> void:
	release_focus()
	get_viewport().gui_release_focus()
	var oid := open_id_line.text.strip_edges()
	if oid == "":
		_set_status("No OpenID yet.")
		return
	DisplayServer.clipboard_set(oid)
	_set_status("Copied OpenID to clipboard.")

func _on_noray_ready(open_id: String) -> void:
	release_focus()
	get_viewport().gui_release_focus()
	print("UI got noray_ready:", open_id)
	open_id_line.text = open_id
	_set_status("Noray ready. Share OpenID to join.")

func _set_status(msg: String) -> void:
	status_label.text = "Status: %s" % msg

func _update_peers() -> void:
	if not multiplayer.has_multiplayer_peer():
		peers_label.text = "Peers: (offline)"
		return

	var ids: Array[int] = []
	ids.append(multiplayer.get_unique_id())
	for p in multiplayer.get_peers():
		ids.append(p)
	ids.sort()
	peers_label.text = "Peers: %s" % str(ids)
