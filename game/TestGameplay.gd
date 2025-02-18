extends Node2D

var p1_network_id: int = 1
var p2_network_id: int = 1
var host_side := Side.P1
var client_side := Side.P2

# handle game ending
@onready var confirm_defeat_timer: NetworkTimer = $ConfirmDefeatTimer

enum Side {
    P1 = 0,
    P2 = 1,
}

var interaction_resolver := InteractionResolver.new()

func _ready():
    SyncManager.sync_started.connect(_on_sync_started)
    SyncManager.sync_stopped.connect(_on_sync_stopped)

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
    
    #SyncManager.start_logging("D:/detailed_logs/logfile_%s" % multiplayer.get_unique_id())
    
    if multiplayer.is_server():
        await get_tree().create_timer(2).timeout
        SyncManager.start()

func _on_sync_started():
    var fighterP1: Player = SyncManager.spawn("fighter0", self, preload("res://player/Player.tscn"), {'x': 100, 'y': 200, 'c': Player.Characters.SPEED, 't': Player.Side.P1}, false);
    #fighterP1.input_retriever.control_type = InputRetriever.ControlType.JOY
    #fighterP1.input_retriever.input_ids = InputRetriever.DEFAULT_CONTROLLER
    fighterP1.set_multiplayer_authority(p1_network_id if host_side == Side.P1 else p2_network_id)
    $UI/BattleHUD/HealthTracker.tracked_player = fighterP1
    fighterP1.defeated.connect(_on_player_defeated)

    var fighterP2: Player = SyncManager.spawn("fighter1", self, preload("res://player/Player.tscn"), {'x': 400, 'y': 200, 'c': Player.Characters.REACH, 't': Player.Side.P2}, false);
    #fighterP2.input_retriever.control_type = InputRetriever.ControlType.JOY
    #fighterP2.input_retriever.input_ids = InputRetriever.DEFAULT_CONTROLLER_2
    fighterP2.input_retriever.input_ids = InputRetriever.DEFAULT_P2
    fighterP2.set_multiplayer_authority(p2_network_id if host_side == Side.P1 else p1_network_id)
    fighterP2.hurtbox_pool.collision_layer = 8
    fighterP2.hurtbox_pool.collision_mask = 4
    fighterP2.hitbox_pool.collision_layer = 2
    fighterP2.hitbox_pool.collision_mask = 1
    fighterP2.scale.x = -1
    $UI/BattleHUD/HealthTracker2.tracked_player = fighterP2
    fighterP2.defeated.connect(_on_player_defeated)
    
    interaction_resolver._setup_players(fighterP1, fighterP2)
    confirm_defeat_timer.timeout.connect(_on_confirm_defeat_timer_timeout.bind([fighterP1, fighterP2]))
    
func _on_sync_stopped():
    SyncManager.stop_logging()


# HANDLE PLAYER DEFEAT #

func _on_player_defeated():
    if not confirm_defeat_timer._running:
        confirm_defeat_timer.start(SyncManager.max_buffer_size)

func _on_confirm_defeat_timer_timeout(players: Array):
    for player in players:
        if player.status == Player.Status.DEFEATED:
            _player_defeat_confirmed(players.filter(func(x): return x != player)[0], player)
            return # TODO: handle double KOs properly.

func _player_defeat_confirmed(winner: Player, loser: Player):
    winner.fsm.force_change_state(Player.State.VICTORY)
    $UI/BattleHUD/MatchOver.visible = true


# MISC.

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        SyncManager.stop()
