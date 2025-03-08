extends Node

@export var map: PackedScene

var player_2_id: int

# Port mapping for online multiplayer
func _ready():
    $InputRemapperDisplay.confirmed.connect(_on_remapper_display_confirmed)
    $InputRemapperDisplay.redo.connect(_on_remap_button_pressed)
    
    $InputMapperLogic.waiting_for_next_input.connect($InputRemapperDisplay._on_waiting_for_next_input)
    $InputMapperLogic.input_received.connect($InputRemapperDisplay._on_input_received)
    $InputMapperLogic.remap_complete.connect($InputRemapperDisplay._on_remap_complete)
    
    $"%MatchOptionsButton".pressed.connect(_on_match_options_pressed)
    $MatchOptionsMenu.closed.connect(_on_match_options_closed)
    
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
    
    $Menu/MarginContainer/VBoxContainer/LocalButton.grab_focus.call_deferred()
    
    _disconnect_existing_peers()

func _disconnect_existing_peers() -> void:
    multiplayer.multiplayer_peer.close()

func _on_local_button_pressed():
    %Menu.hide()
    load_game(1, 1)

func _on_match_options_pressed():
    $Menu.hide()
    $MatchOptionsMenu.open()

func _on_match_options_closed():
    $Menu.show()
    $MatchOptionsMenu.hide()

func _on_remap_button_pressed(side: Player.Side):
    $Menu.hide()
    $InputRemapperDisplay.start(side)
    if side == Player.Side.P1:
        InputMappingManager.p1_input_mapping = await $InputMapperLogic.collect_input_mapping()
    elif side == Player.Side.P2:
        InputMappingManager.p2_input_mapping = await $InputMapperLogic.collect_input_mapping()

func _on_remapper_display_confirmed():
    $InputRemapperDisplay.hide()
    $Menu.show()
    $"Menu/MarginContainer/VBoxContainer/Remap P1 Input".grab_focus.call_deferred()

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
    var options: MatchOptions = $MatchOptionsMenu.get_match_options()

    if p2_id == 0:
        p2_id = multiplayer.get_unique_id()
    
    %Menu.hide()
    if %MapInstance.get_children().size() > 0 && %MapInstance.get_child(0):
        %MapInstance.get_child(0).queue_free()
    
    var instantiated_map = map.instantiate()
    instantiated_map.init_options(options)
    instantiated_map.p1_network_id = p1_id
    instantiated_map.p2_network_id = p2_id
    %MapInstance.add_child(instantiated_map)

func add_player_and_start_game(id):
    player_2_id = id
    load_game(1, player_2_id)

@rpc("any_peer")
func remove_player(id):
    #_disconnect_existing_peers()
    #%Menu.show()
    pass

func server_offline():
    #_disconnect_existing_peers()
    #%Menu.show()
    pass
