extends Node2D

var p1_network_id: int = 1
var p2_network_id: int = 1

func _ready():
	SyncManager.sync_started.connect(_on_sync_started)

	if p1_network_id != p2_network_id:
		SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/RPCNetworkAdaptor.gd").new())
	else:
		SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd").new())
	for id in [p1_network_id, p2_network_id]:
		if id != multiplayer.get_unique_id():
			SyncManager.add_peer(id)
	
	if multiplayer.is_server():
		await get_tree().create_timer(2).timeout
		SyncManager.start()

func _on_sync_started():
	SyncManager.spawn("fighter", self, preload("res://player/Player.tscn"), {'x': 100, 'y': 200, 'c': Player.Characters.SPEED});
	# spawn another fighter
