class_name TestGameplay extends Node2D

const STAGE_WIDTH: int = 512

var p1_network_id: int = 1
var p2_network_id: int = 1
var host_side := Side.P1
var client_side := Side.P2

var match_options: MatchOptions

# handle game ending
@onready var confirm_defeat_timer: NetworkTimer = $ConfirmDefeatTimer
@onready var start_new_round_timer: NetworkTimer = $StartNewRoundTimer
@onready var health_tracker_1: HealthTracker = $UI/BattleHUD/HealthTracker
@onready var health_tracker_2: HealthTracker = $UI/BattleHUD/HealthTracker2
@onready var win_tracker_1: WinTracker = $UI/BattleHUD/WinTracker
@onready var win_tracker_2: WinTracker = $UI/BattleHUD/WinTracker2

@onready var camera_control: CameraControl = $CameraControl

enum Side {
    P1 = 0,
    P2 = 1,
}

var interaction_resolver := InteractionResolver.new()

func init_options(options: MatchOptions) -> void:
    match_options = options

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
    if match_options == null:
        push_error("Match Options is unset. Falling back to default options...")
        match_options = MatchOptions.generate_default()

    var fighterP1: Player = SyncManager.spawn("fighter0", self, preload("res://player/Player.tscn"), {'x': - 200, 'y': 300, 'c': Player.Characters.SPEED, 't': Player.Side.P1}, false);
    fighterP1.set_multiplayer_authority(p1_network_id if host_side == Side.P1 else p2_network_id)
    fighterP1.input_retriever = match_options.input_retrievers[0]
    health_tracker_1.tracked_player = fighterP1
    fighterP1.defeated.connect(_on_player_defeated)

    var fighterP2: Player = SyncManager.spawn("fighter1", self, preload("res://player/Player.tscn"), {'x': 200, 'y': 300, 'c': Player.Characters.REACH, 't': Player.Side.P2}, false);
    fighterP2.set_multiplayer_authority(p2_network_id if host_side == Side.P1 else p1_network_id)

    # when playing online as p2, use the "normal" p1 mapping the player set up.
    if fighterP2.is_multiplayer_authority() and p1_network_id != p2_network_id:
        fighterP2.input_retriever = match_options.input_retrievers[0]
    else:
        fighterP2.input_retriever = match_options.input_retrievers[1]

    fighterP2.hurtbox_pool.collision_layer = 8
    fighterP2.hurtbox_pool.collision_mask = 4
    fighterP2.hitbox_pool.collision_layer = 2
    fighterP2.hitbox_pool.collision_mask = 1
    fighterP2.scale.x = -1
    health_tracker_2.tracked_player = fighterP2
    fighterP2.defeated.connect(_on_player_defeated)
    
    interaction_resolver._setup_players(fighterP1, fighterP2)
    interaction_resolver.camera_control = camera_control
    camera_control._sync_start_initialize([fighterP1, fighterP2])

    confirm_defeat_timer.timeout.connect(_on_confirm_defeat_timer_timeout.bind([fighterP1, fighterP2]))
    start_new_round_timer.timeout.connect(_on_start_new_round_timer_timeout.bind([fighterP1, fighterP2]))
    
    $AudioStreamPlayer.play()
    $UI/BattleHUD.show()


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
    #TODO: use a smarter method to tell which player is which:
    if health_tracker_1.tracked_player == winner:
        win_tracker_1.increment_wins()
    else:
        win_tracker_2.increment_wins()
        
    $UI/BattleHUD/MatchOver.visible = true
    # wait for some time, then do setup necessary to set up next round.
    const ticks_per_sec := 60
    start_new_round_timer.start(ticks_per_sec)
    # call reset on both players

# MISC.

func _on_start_new_round_timer_timeout(players: Array):
    for player in players:
        player.reset()
    $UI/BattleHUD/MatchOver.visible = false

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        SyncManager.stop()
