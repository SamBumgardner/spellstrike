class_name TestGameplay extends Node2D

const STAGE_WIDTH: int = 512

var p1_network_id: int = 1
var p2_network_id: int = 1
var host_side := Side.P1
var client_side := Side.P2

var match_options: MatchOptions

var player_wins: Array[int] = [0, 0]

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

@onready var wins_manager: WinsManager = $WinsManager
@onready var interaction_resolver: InteractionResolver = $InteractionResolver
@onready var camera_control: CameraControl = $CameraControl
@onready var round_timer: NetworkTimer = $RoundTimer

var players: Array = []

enum Side {
    P1 = 0,
    P2 = 1,
}

func init_options(options: MatchOptions) -> void:
    match_options = options

func init_wins_record(starting_wins: Array[int]) -> void:
    player_wins = starting_wins

func _ready():
    wins_manager.initialize_records(player_wins)
    
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
            if id != multiplayer.get_unique_id() and id not in SyncManager.peers:
                SyncManager.add_peer(id)
    else:
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd").new())

    # SyncManager.start_logging("D:/detailed_logs/logfile_%s" % multiplayer.get_unique_id())
    
    if multiplayer.is_server():
        $StartMatchTimer.start(2)
        $StartMatchTimer.timeout.connect(SyncManager.start)

    round_timer.timeout.connect(_on_round_timer_timeout)

    wins_manager.round_won.connect(_on_round_won)
    wins_manager.round_tied.connect(_on_round_tied)
    wins_manager.game_won.connect(_on_game_won)
    wins_manager.play_next_round.connect(_on_play_next_round)
    
    for tracker in [$UI/BattleHUD/RoundsTracker, $UI/BattleHUD/RoundsTracker2]:
        tracker.initialize_rounds(0, MatchOptions.default_rounds_to_win)

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

    players = [fighterP1, fighterP2]
    
    interaction_resolver._setup_players(fighterP1, fighterP2)
    interaction_resolver.camera_control = camera_control
    camera_control._sync_start_initialize([fighterP1, fighterP2])

    confirm_defeat_timer.timeout.connect(_on_confirm_defeat_timer_timeout)
    start_new_round_timer.timeout.connect(_on_start_new_round_timer_timeout)
    
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

func _on_confirm_defeat_timer_timeout():
    var winning_player: Player = null
    var defeated_players: Array = []
    for player in players:
        if player.status == Player.Status.DEFEATED:
            defeated_players.append(player)
        else:
            winning_player = player
        
    _end_round(winning_player, defeated_players)

func _end_round(winning_player: Player, defeated_players: Array):
    wins_manager.round_completed(winning_player, defeated_players)
    start_new_round_timer.start(MatchOptions.ticks_per_second)

func _on_round_won(winning_side: Player.Side, losing_sides: Array) -> void:
    players[winning_side].receive_victory()
    for side in losing_sides:
        players[side].receive_defeat()

    $UI/BattleHUD/MatchOver.visible = true
    $UI/BattleHUD/MatchOver.text = "PLAYER %s WINS!" % (winning_side + 1)
    #TODO: Trigger more exciting end of round effects

func _on_round_tied() -> void:
    for player in players:
        player.receive_defeat()

    $UI/BattleHUD/MatchOver.visible = true
    $UI/BattleHUD/MatchOver.text = "TIE ROUND!"

func _on_play_next_round(new_round_number: int) -> void:
    for player in players:
        player.reset()
    $UI/BattleHUD/MatchOver.visible = false
    print_debug("starting round %s" % new_round_number)
    round_timer.start(match_options.default_ticks_per_round)

func _on_game_won(side: Player.Side) -> void:
    print_debug("game is over, P%s won, should pop up some kind of post-game menu" % (side + 1))
    SyncManager.stop()
    # initialize 
    var rematch_screen_packed = preload("res://network/postgame.tscn")
    var rematch_screen = rematch_screen_packed.instantiate()
    rematch_screen.init_options(match_options)
    rematch_screen.init_wins_record(wins_manager.get_game_win_counts())
    rematch_screen.p1_network_id = p1_network_id
    rematch_screen.p2_network_id = p2_network_id
    SceneSwitchUtil.change_scene(get_tree(), rematch_screen)

# MISC.

func _on_player_requested_projectile(projectile_type: Projectile.ProjectileType, requestor: Player) -> void:
    var new_projectile = SyncManager.spawn("projectile", self, preload("res://player/projectile/Projectile.tscn"), {'x': requestor.position.x, 'y': requestor.position.y, 'pt': projectile_type, 't': requestor.team, 'fd': requestor.facing_direction, 'sx': requestor.scale.x})
    interaction_resolver.register_new_projectile(new_projectile)

func _on_start_new_round_timer_timeout():
    wins_manager.check_game_finished()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        SyncManager.stop()
