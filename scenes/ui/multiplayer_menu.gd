extends Control

@onready var open_id_line: LineEdit = $PanelContainer/VBoxContainer/HBoxContainer2/OpenIdLine
@onready var join_line: LineEdit = $PanelContainer/VBoxContainer/HBoxContainer3/JoinLine
@onready var relay_check: CheckBox = $PanelContainer/VBoxContainer/HBoxContainer4/RelayCheck
@onready var status_label: Label = $PanelContainer/VBoxContainer/StatusLabel
@onready var peers_label: Label = $PanelContainer/VBoxContainer/PeersLabel

func _ready() -> void:
	print("UI ready. Network_Manager is:", Network_Manager)

	Network_Manager.noray_ready.connect(func(oid: String):
		print("UI got noray_ready:", oid)
		_on_noray_ready(oid)
		)
		
	# Buttons
	$PanelContainer/VBoxContainer/HBoxContainer/HostButton.pressed.connect(_on_host_pressed)
	$PanelContainer/VBoxContainer/HBoxContainer2/CopyButton.pressed.connect(_on_copy_pressed)
	$PanelContainer/VBoxContainer/HBoxContainer4/JoinButton.pressed.connect(_on_join_pressed)


	# NetworkManager signals
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
	if open_id_line.text.strip_edges() == "":
		_set_status("No OpenID yet.")
		return
	DisplayServer.clipboard_set(open_id_line.text)
	_set_status("Copied OpenID to clipboard.")

func _on_noray_ready(open_id: String) -> void:
	open_id_line.text = open_id
	# Helpful: auto-fill join box when testing on same PC
	# join_line.text = open_id
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
