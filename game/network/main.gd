extends Node

@export var map : PackedScene

var player_2_id : int

# Port mapping for online multiplayer
func _ready():
	if OS.get_name() != "Web":
		# not friendly with sam's current router, but also not required for testing.

		# var upnp = UPNP.new()
		# upnp.discover()
		# var result = upnp.add_port_mapping(9999)
		# %DisplayPublicIP.text = " " + upnp.query_external_address()
		pass
	else:
		%DisplayPublicIP.hide()
		$Menu/MarginContainer/VBoxContainer/Label2.hide()
		$Menu/MarginContainer/VBoxContainer/HostButton.hide()
		$Menu/MarginContainer/VBoxContainer/Label.hide()
		%To.hide()
		$Menu/MarginContainer/VBoxContainer/JoinButton.hide()
		

func _on_local_button_pressed():
	%Menu.hide()
	load_game(1, 1)

# Server
func _on_host_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(add_player_and_start_game)
	multiplayer.peer_disconnected.connect(remove_player)
	
	%Menu.hide()

# Client
func _on_join_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(%To.text, 9999)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(load_game)
	multiplayer.server_disconnected.connect(server_offline)

func load_game(p1_id = 1, p2_id = 0):
	if p2_id == 0:
		p2_id = multiplayer.get_unique_id()
	
	%Menu.hide()
	if %MapInstance.get_children().size() > 0 && %MapInstance.get_child(0):
		%MapInstance.get_child(0).queue_free()
	
	var instantiated_map = map.instantiate()
	instantiated_map.p1_network_id = p1_id
	instantiated_map.p2_network_id = p2_id
	%MapInstance.add_child(instantiated_map)

func add_player_and_start_game(id):
	player_2_id = id
	load_game(1, player_2_id)

@rpc("any_peer")
func remove_player(id):
	%Menu.show()
	if %MapInstance.get_child(0):
		%MapInstance.get_child(0).queue_free()

func server_offline():
	%Menu.show()
	if %MapInstance.get_child(0):
		%MapInstance.get_child(0).queue_free()
