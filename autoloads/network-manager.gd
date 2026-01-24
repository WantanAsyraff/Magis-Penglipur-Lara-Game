extends Node
class_name NetworkManager

const MAX_PLAYERS := 4

# Public test Noray (good for dev, not shipping)
@export var noray_host: String = "tomfol.io"
@export var noray_port: int = 8890

signal noray_ready(open_id: String) # show this in UI so friends can join
signal connected_to_host
signal connection_failed(err: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

var _is_host := false
var open_id := ""

func _ready() -> void:
	# Noray connect callbacks (NAT + relay)
	Noray.on_connect_nat.connect(_handle_connect)
	Noray.on_connect_relay.connect(_handle_connect)

	# Godot multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(func():
		connected_to_host.emit()
	)

	multiplayer.connection_failed.connect(func():
		connection_failed.emit(ERR_CANT_CONNECT)
	)

	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ------------------------------------------------------------
# Public API
# ------------------------------------------------------------

func host_game() -> void:
	_is_host = true

	var err := await _noray_bootstrap()
	if err != OK:
		connection_failed.emit(err)
		return

	# Host listens on Noray.local_port (not a fixed PORT) :contentReference[oaicite:1]{index=1}
	var peer := ENetMultiplayerPeer.new()
	err = peer.create_server(Noray.local_port, MAX_PLAYERS)
	if err != OK:
		connection_failed.emit(err)
		return

	multiplayer.multiplayer_peer = peer

	# spawn host
	_spawn_player_for(1)
	player_joined.emit(1)

	# share open_id
	noray_ready.emit(open_id)

func join_game(host_open_id: String, use_relay: bool = false) -> void:
	_is_host = false

	var err := await _noray_bootstrap()
	if err != OK:
		connection_failed.emit(err)
		return

	# Ask Noray to connect to the host using their OpenID :contentReference[oaicite:2]{index=2}
	if use_relay:
		Noray.connect_relay(host_open_id)
	else:
		Noray.connect_nat(host_open_id)

# ------------------------------------------------------------
# Noray bootstrap (connect + register)
# ------------------------------------------------------------

func _noray_bootstrap() -> int:
	var err := await Noray.connect_to_host(noray_host, noray_port)
	if err != OK:
		return err

	# Request IDs (OpenID + PrivateID) :contentReference[oaicite:3]{index=3}
	Noray.register_host()
	await Noray.on_oid
	await Noray.on_pid

	open_id = Noray.open_id
	noray_ready.emit(open_id)

	# Register remote address so Noray sets Noray.local_port :contentReference[oaicite:4]{index=4}
	err = await Noray.register_remote()
	return err

# ------------------------------------------------------------
# Called by Noray when it found how to connect (NAT or Relay)
# ------------------------------------------------------------

func _handle_connect(address: String, port: int) -> Error:
	if _is_host:
		# Host-side handshake over the existing ENet server :contentReference[oaicite:5]{index=5}
		var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if enet == null:
			return ERR_UNCONFIGURED
		return await PacketHandshake.over_enet(enet.host, address, port)

	# Client-side: handshake via UDP bound to Noray.local_port, then ENet connect :contentReference[oaicite:6]{index=6}
	var udp := PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)

	var err := await PacketHandshake.over_packet_peer(udp)
	udp.close()
	if err != OK:
		return err

	var peer := ENetMultiplayerPeer.new()
	# IMPORTANT: local port must be Noray.local_port or connectivity breaks :contentReference[oaicite:7]{index=7}
	err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = peer
	return OK

# ------------------------------------------------------------
# Spawn sync (your project needs this)
# ------------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	player_joined.emit(peer_id)

	if not multiplayer.is_server():
		return

	# Tell the newly joined peer to spawn all existing peers
	var existing: Array[int] = [1]
	for id in multiplayer.get_peers():
		existing.append(id)
	rpc_id(peer_id, "rpc_spawn_existing", existing)

	# Spawn the newcomer and broadcast
	_spawn_player_for(peer_id)
	rpc("rpc_spawn_player", peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	player_left.emit(peer_id)

	Player_Manager.remove_player(peer_id)
	if multiplayer.is_server():
		rpc("rpc_remove_player", peer_id)

func _on_server_disconnected() -> void:
	# Client lost host: clear what you have
	for id in Player_Manager.players.keys():
		Player_Manager.remove_player(int(id))

func _spawn_player_for(peer_id: int) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return

	var pos := _get_default_spawn_pos(scene, peer_id)
	Player_Manager.spawn_player_for_peer(scene, pos, peer_id)


func _get_default_spawn_pos(scene: Node, peer_id: int) -> Vector2:
	var base := Vector2.ZERO
	var spawns := scene.find_child("SpawnPoints", true, false)
	if spawns:
		var marker := spawns.get_node_or_null("entrance")
		if marker and marker is Node2D:
			base = marker.global_position

	var offsets: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(24, 0),
	Vector2(-24, 0),
	Vector2(0, 24),
	]

	var idx: int = clamp(peer_id - 1, 0, offsets.size() - 1)
	return base + offsets[idx]


@rpc("authority", "call_local")
func rpc_spawn_player(peer_id: int) -> void:
	_spawn_player_for(peer_id)

@rpc("authority", "call_local")
func rpc_remove_player(peer_id: int) -> void:
	Player_Manager.remove_player(peer_id)

@rpc("authority", "call_local")
func rpc_spawn_existing(peer_ids: Array[int]) -> void:
	for id in peer_ids:
		_spawn_player_for(int(id))
