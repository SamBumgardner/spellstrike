extends Node2D

var p1_network_id: int = 1
var p2_network_id: int = 1
var host_side := Side.P1
var client_side := Side.P2

enum Side {
	P1 = 0,
	P2 = 1,
}

func _ready():
	SyncManager.sync_started.connect(_on_sync_started)

	if p1_network_id != p2_network_id:
		SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/RPCNetworkAdaptor.gd").new())
		var producer_side = host_side if multiplayer.is_server() else client_side
		var receiver_side = client_side if multiplayer.is_server() else host_side
		SyncManager.message_serializer.produce_input_path = "%s/fighter%s" % [get_path(), producer_side]
		SyncManager.message_serializer.receive_input_path = "%s/fighter%s" % [get_path(), receiver_side]
	else:
		SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd").new())

	for id in [p1_network_id, p2_network_id]:
		if id != multiplayer.get_unique_id():
			SyncManager.add_peer(id)
	
	if multiplayer.is_server():
		await get_tree().create_timer(2).timeout
		SyncManager.start()

func _on_sync_started():
	var fighterP1 = SyncManager.spawn("fighter0", self, preload("res://player/Player.tscn"), {'x': 100, 'y': 200, 'c': Player.Characters.SPEED}, false);
	fighterP1.set_multiplayer_authority(p1_network_id if host_side == Side.P1 else p2_network_id)

	var fighterP2 = SyncManager.spawn("fighter1", self, preload("res://player/Player.tscn"), {'x': 400, 'y': 200, 'c': Player.Characters.REACH}, false);
	fighterP2.input_retriever.input_ids = InputRetriever.DEFAULT_P2
	fighterP2.set_multiplayer_authority(p2_network_id if host_side == Side.P1 else p1_network_id)
	# spawn another fighter
