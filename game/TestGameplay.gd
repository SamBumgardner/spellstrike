class_name TestGameplay extends Node2D

const STAGE_WIDTH: int = 512

var player_informations: Array[PlayerInformation]
var match_options: MatchOptions

var network_ids: Array

# non-gameplay UI
@onready var notification_window: Notification = $UI/Notification
const NETWORK_ERROR_TYPE: String = "NETWORK"
const DESYNC_ERROR_FORMAT: String = "Desync ocurred. Match has been cancelled.\rReturning to the network menu..."
const CONNECTION_LOST_ERROR_FORMAT: String = "Connection lost. Match has been cancelled.\rReturning to the network menu..."

# handle game ending
@onready var confirm_defeat_timer: NetworkTimer = $ConfirmDefeatTimer
@onready var start_new_round_timer: NetworkTimer = $StartNewRoundTimer
@onready var health_trackers: Array[HealthTracker] = [$UI/BattleHUD/HealthTracker, $UI/BattleHUD/HealthTracker2]
@onready var win_trackers: Array[WinTracker] = [$UI/BattleHUD/WinTracker, $UI/BattleHUD/WinTracker2]
@onready var combo_counters: Array[ComboCounter] = [$UI/BattleHUD/ComboCounter, $UI/BattleHUD/ComboCounter2]
@onready var special_counters: Array[SpecialCounter] = [$UI/BattleHUD/SpecialCounter, $UI/BattleHUD/SpecialCounter2]
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

func init(
    new_options: MatchOptions,
    new_player_informations: Array[PlayerInformation]
) -> void:
    match_options = new_options
    player_informations = new_player_informations
    network_ids = player_informations.map(func(x): return x.network_id)

func _ready():
    var win_records: Array[int]
    win_records.assign(player_informations.map(func(x): return x.number_of_wins))
    wins_manager.initialize_records(win_records)
    
    SyncManager.sync_started.connect(_on_sync_started)
    SyncManager.sync_stopped.connect(_on_sync_stopped)
    SyncManager.sync_error.connect(_on_sync_error)

    if network_ids[Side.P1] != network_ids[Side.P2]:
        multiplayer.multiplayer_peer.peer_disconnected.connect(_on_broken_connection)
        
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/RPCNetworkAdaptor.gd").new())

        var producer_side = Side.P1 if network_ids[Side.P1] == multiplayer.get_unique_id() else Side.P2
        var receiver_side = Side.P1 if network_ids[Side.P2] == multiplayer.get_unique_id() else Side.P2
        SyncManager.message_serializer.produce_input_path = "%s/fighter%s" % [get_path(), producer_side]
        SyncManager.message_serializer.receive_input_path = "%s/fighter%s" % [get_path(), receiver_side]
        for id in network_ids:
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
    
    round_timer_display.set_initial_display(match_options.default_ticks_per_round)
    for tracker in [$UI/BattleHUD/RoundsTracker, $UI/BattleHUD/RoundsTracker2]:
        tracker.initialize_rounds(0, MatchOptions.default_rounds_to_win)

func _on_sync_started():
    if match_options == null:
        push_error("Match Options is unset. Falling back to default options...")
        match_options = MatchOptions.generate_default()

    var fighterP1: Player = _spawn_fighter(player_informations[Side.P1], Side.P1)
    var fighterP2: Player = _spawn_fighter(player_informations[Side.P2], Side.P2)
    fighterP1.opponent = fighterP2
    fighterP2.opponent = fighterP1

    players = [fighterP1, fighterP2]
    
    interaction_resolver._setup_players(fighterP1, fighterP2)
    interaction_resolver.camera_control = camera_control
    camera_control._sync_start_initialize([fighterP1, fighterP2])

    confirm_defeat_timer.timeout.connect(_on_confirm_defeat_timer_timeout)
    start_new_round_timer.timeout.connect(_on_start_new_round_timer_timeout)
    
    $AudioStreamPlayer.play()
    $UI/BattleHUD.show()
    
    round_timer.start(match_options.default_ticks_per_round)

func _spawn_fighter(player_information: PlayerInformation, side: int) -> Player:
    var start_position: Vector2i = Vector2i.ZERO
    match side:
        Side.P1:
            start_position.x = -200
            start_position.y = 420
        Side.P2:
            start_position.x = 200
            start_position.y = 420
    
    var fighter: Player = SyncManager.spawn("fighter%s" % side, self, preload("res://player/Player.tscn"), {'x': start_position.x, 'y': start_position.y, 'character_spec': player_information.character_spec, 't': side}, false);
    fighter.set_multiplayer_authority(player_information.network_id)
    fighter.input_retriever = player_information.input_retriever

    health_trackers[side].tracked_player = fighter
    combo_counters[side].tracked_player = fighter
    special_counters[side].tracked_player = fighter
    fighter.defeated.connect(_on_player_defeated)
    fighter.request_projectile.connect(_on_player_requested_projectile)

    return fighter

func _on_sync_error(_msg: String):
    # communicate that a fatal state mismatch occurred. 
    var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, DESYNC_ERROR_FORMAT)
    closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)
    
func _on_broken_connection(disconnected_peer_id: int):
    if disconnected_peer_id in network_ids:
        _close_rollback_networking()
        var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, CONNECTION_LOST_ERROR_FORMAT)
        closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)

func _close_rollback_networking():
    $StartMatchTimer.stop()
    SyncManager.clear_peers()
    # Leaves godot high-level multiplayer connection intact.

func _return_to_network_menu() -> void:
    print_debug("I'm returning to the network menu!")
    var main_menu_scene = load("res://network/main.tscn").instantiate()
    SceneSwitchUtil.change_scene(get_tree(), main_menu_scene)

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
    player_informations[winning_side].number_of_wins += 1
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

func _on_game_won(winning_side: Player.Side) -> void:
    SyncManager.stop()
    # initialize 
    var rematch_screen_packed = preload("res://network/postgame.tscn")
    var rematch_screen = rematch_screen_packed.instantiate()
    
    rematch_screen.init(
        match_options,
        player_informations,
        winning_side,
    )
    SceneSwitchUtil.change_scene(get_tree(), rematch_screen)

# MISC.
static var projectile_specs = {
    Projectile.ProjectileType.DELAYED_BLAST_FIREBALL: load("res://assets/data/states/projectile/delay_fireball/delay_fireball_projectile_spec.tres"),
    Projectile.ProjectileType.EARTH_SPIKE: load("res://assets/data/states/projectile/earth_spike/earth_spike_projectile_spec.tres"),
}

func _on_player_requested_projectile(projectile_type: int, requestor: Player) -> void:
    var projectile_spec: ProjectileSpec = projectile_specs[projectile_type]

    var start_x = requestor.position.x
    var start_y = requestor.position.y
    match projectile_spec.spawn_location_x:
        ProjectileSpec.SpawnLocation.ON_ENEMY:
            start_x = requestor.opponent.position.x

    var new_projectile = SyncManager.spawn("projectile", self, preload("res://player/projectile/Projectile.tscn"), {'x': start_x, 'y': start_y, 'projectile_spec': projectile_spec, 't': requestor.team, 'fd': requestor.facing_direction, 'sx': requestor.scale.x, 'opponent': requestor.opponent})
    interaction_resolver.register_new_projectile(new_projectile)
    if not new_projectile.expired.is_connected(_on_projectile_expired):
        new_projectile.expired.connect(_on_projectile_expired)

    players[new_projectile.team].active_projectiles += 1

func _on_projectile_expired(projectile: Projectile) -> void:
    players[projectile.team].active_projectiles -= 1

func _on_start_new_round_timer_timeout():
    wins_manager.check_game_finished()

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        SyncManager.stop()
