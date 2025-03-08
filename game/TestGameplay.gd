class_name TestGameplay extends Node2D

const STAGE_WIDTH: int = 512

var p1_network_id: int = 1
var p2_network_id: int = 1
var host_side := Side.P1
var client_side := Side.P2

var match_options: MatchOptions

# non-gameplay UI
@onready var notification_window: Notification = $UI/Notification
const NETWORK_ERROR_TYPE: String = "NETWORK"
const DESYNC_ERROR_FORMAT: String = "Desync ocurred. Match has been cancelled.\rReturning to the network menu..."
const CONNECTION_LOST_ERROR_FORMAT: String = "Connection lost. Match has been cancelled.\rReturning to the network menu..."

# handle game ending
@onready var confirm_defeat_timer: NetworkTimer = $ConfirmDefeatTimer
@onready var start_new_round_timer: NetworkTimer = $StartNewRoundTimer
@onready var health_tracker_1: HealthTracker = $UI/BattleHUD/HealthTracker
@onready var health_tracker_2: HealthTracker = $UI/BattleHUD/HealthTracker2
@onready var win_tracker_1: WinTracker = $UI/BattleHUD/WinTracker
@onready var win_tracker_2: WinTracker = $UI/BattleHUD/WinTracker2
@onready var combo_counter_1: ComboCounter = $UI/BattleHUD/ComboCounter
@onready var combo_counter_2: ComboCounter = $UI/BattleHUD/ComboCounter2
@onready var special_counter_1: SpecialCounter = $UI/BattleHUD/SpecialCounter
@onready var special_counter_2: SpecialCounter = $UI/BattleHUD/SpecialCounter2
@onready var round_timer_display: RoundTimerDisplay = $UI/BattleHUD/RoundTimerDisplay

@onready var interaction_resolver: InteractionResolver = $InteractionResolver
@onready var camera_control: CameraControl = $CameraControl
@onready var round_timer: NetworkTimer = $RoundTimer

enum Side {
    P1 = 0,
    P2 = 1,
}

func init_options(options: MatchOptions) -> void:
    match_options = options

func _ready():
    SyncManager.sync_started.connect(_on_sync_started)
    SyncManager.sync_stopped.connect(_on_sync_stopped)
    SyncManager.sync_error.connect(_on_sync_error)

    if p1_network_id != p2_network_id:
        multiplayer.multiplayer_peer.peer_disconnected.connect(_on_broken_connection)
        
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/RPCNetworkAdaptor.gd").new())
        var producer_side = host_side if multiplayer.is_server() else client_side
        var receiver_side = client_side if multiplayer.is_server() else host_side
        SyncManager.message_serializer.produce_input_path = "%s/fighter%s" % [get_path(), producer_side]
        SyncManager.message_serializer.receive_input_path = "%s/fighter%s" % [get_path(), receiver_side]
        for id in [p1_network_id, p2_network_id]:
            if id != multiplayer.get_unique_id():
                SyncManager.add_peer(id)
    else:
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd").new())

    # SyncManager.start_logging("D:/detailed_logs/logfile_%s" % multiplayer.get_unique_id())
    
    if multiplayer.is_server():
        $StartMatchTimer.start(2)
        $StartMatchTimer.timeout.connect(SyncManager.start)

    round_timer.timeout.connect(_on_round_timer_timeout)

func _on_sync_started():
    if match_options == null:
        push_error("Match Options is unset. Falling back to default options...")
        match_options = MatchOptions.generate_default()

    var fighterP1: Player = SyncManager.spawn("fighter0", self, preload("res://player/Player.tscn"), {'x': - 200, 'y': 420, 'c': Player.Characters.SPEED, 't': Player.Side.P1}, false);
    fighterP1.set_multiplayer_authority(p1_network_id if host_side == Side.P1 else p2_network_id)
    fighterP1.input_retriever = match_options.input_retrievers[0]
    health_tracker_1.tracked_player = fighterP1
    combo_counter_1.tracked_player = fighterP1
    special_counter_1.tracked_player = fighterP1
    
    fighterP1.defeated.connect(_on_player_defeated)
    fighterP1.request_projectile.connect(_on_player_requested_projectile)

    var fighterP2: Player = SyncManager.spawn("fighter1", self, preload("res://player/Player.tscn"), {'x': 200, 'y': 420, 'c': Player.Characters.REACH, 't': Player.Side.P2}, false);
    fighterP2.set_multiplayer_authority(p2_network_id if host_side == Side.P1 else p1_network_id)

    # when playing online as p2, use the "normal" p1 mapping the player set up.
    if fighterP2.is_multiplayer_authority() and p1_network_id != p2_network_id:
        fighterP2.input_retriever = match_options.input_retrievers[0]
    else:
        fighterP2.input_retriever = match_options.input_retrievers[1]

    health_tracker_2.tracked_player = fighterP2
    combo_counter_2.tracked_player = fighterP2
    special_counter_2.tracked_player = fighterP2
    fighterP2.defeated.connect(_on_player_defeated)
    fighterP2.request_projectile.connect(_on_player_requested_projectile)
    
    interaction_resolver._setup_players(fighterP1, fighterP2)
    interaction_resolver.camera_control = camera_control
    camera_control._sync_start_initialize([fighterP1, fighterP2])

    confirm_defeat_timer.timeout.connect(_on_confirm_defeat_timer_timeout.bind([fighterP1, fighterP2]))
    start_new_round_timer.timeout.connect(_on_start_new_round_timer_timeout.bind([fighterP1, fighterP2]))
    
    $AudioStreamPlayer.play()
    $UI/BattleHUD.show()
    
    round_timer.start(match_options.default_ticks_per_round)

func _on_sync_error(_msg: String):
    # communicate that a fatal state mismatch occurred. 
    var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, DESYNC_ERROR_FORMAT)
    closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)
    
func _on_broken_connection(disconnected_peer_id: int):
    if disconnected_peer_id in [p1_network_id, p2_network_id]:
        _close_rollback_networking()
        var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, CONNECTION_LOST_ERROR_FORMAT)
        closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)

func _close_rollback_networking():
    $StartMatchTimer.stop()
    SyncManager.clear_peers()
    # Leaves godot high-level multiplayer connection intact.

func _return_to_network_menu() -> void:
    print_debug("I'm returning to the network menu!")
    var main_menu_scene = SceneSwitchUtil.main_menu_scene.instantiate()
    SceneSwitchUtil.change_scene(get_tree(), main_menu_scene)
    pass # return to network menu

func _on_sync_stopped(reason: Disconnect.Reason):
    SyncManager.stop_logging()
    
    if reason == Disconnect.Reason.DESYNC:
        _on_sync_error("")

# HANDLE PLAYER DEFEAT #
func _on_round_timer_timeout():
    var round_timeout_result = interaction_resolver.decide_timeout_results()
    if round_timeout_result.winning_player != null:
        _end_round(round_timeout_result.winning_player, [round_timeout_result.losing_player])
    else:
        _end_round(null, round_timeout_result.tie_players)

func _on_player_defeated():
    if not confirm_defeat_timer._running:
        round_timer.stop()
        confirm_defeat_timer.start(SyncManager.max_buffer_size)

func _on_confirm_defeat_timer_timeout(players: Array):
    var winning_player: Player = null
    var defeated_players: Array = []
    for player in players:
        if player.status == Player.Status.DEFEATED:
            defeated_players.append(player)
        else:
            winning_player = player
        
    _end_round(winning_player, defeated_players)

func _end_round(winning_player: Player, defeated_players: Array):
    if winning_player != null:
        winning_player.receive_victory()
        #TODO: use a smarter method to tell which player is which:
        if winning_player.team == Player.Side.P1:
            win_tracker_1.increment_wins()
        else:
            win_tracker_2.increment_wins()
      
    for loser in defeated_players:
        loser.receive_defeat()
    
    if winning_player != null:
        $UI/BattleHUD/MatchOver.visible = true
        $UI/BattleHUD/MatchOver.text = "PLAYER %s WINS!" % (winning_player.team + 1)
        #TODO: Trigger more exciting end of round effects
    else:
        $UI/BattleHUD/MatchOver.visible = true
        $UI/BattleHUD/MatchOver.text = "TIE ROUND\rGO AGAIN!"
    
    # wait for some time, then do setup necessary to set up next round.
    const ticks_per_sec := 60
    start_new_round_timer.start(ticks_per_sec)
    # call reset on both players

# MISC.

func _on_player_requested_projectile(projectile_type: Projectile.ProjectileType, requestor: Player) -> void:
    var new_projectile = SyncManager.spawn("projectile", self, preload("res://player/projectile/Projectile.tscn"), {'x': requestor.position.x, 'y': requestor.position.y, 'pt': projectile_type, 't': requestor.team, 'fd': requestor.facing_direction, 'sx': requestor.scale.x})
    interaction_resolver.register_new_projectile(new_projectile)

func _on_start_new_round_timer_timeout(players: Array):
    for player in players:
        player.reset()
    $UI/BattleHUD/MatchOver.visible = false
    round_timer.start(match_options.default_ticks_per_round)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        SyncManager.stop()
