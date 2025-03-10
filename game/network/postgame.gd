class_name Postgame extends Control

const POST_SELECTION_DURATION = MatchOptions.ticks_per_second * 10

@onready var notification_window: Notification = $UI/Notification
const NETWORK_ERROR_TYPE: String = "NETWORK"
const DESYNC_ERROR_FORMAT: String = "Desync ocurred. Match has been cancelled.\rReturning to the network menu..."
const CONNECTION_LOST_ERROR_FORMAT: String = "Connection lost. Match has been cancelled.\rReturning to the network menu..."

@onready var results_boxes: Array = [$"%ResultsBox", $"%ResultsBox2"]
@onready var rematch_menus: Array = [$"%RematchMenu", $"%RematchMenu2"]
@onready var post_selection_delay_timer: NetworkTimer = $PostSelectionDelay

var match_options: MatchOptions
var player_informations: Array[PlayerInformation]
var winning_side: Player.Side = Player.Side.P1

func init_options(new_options: MatchOptions) -> void:
    match_options = new_options

func init(new_options: MatchOptions,
    new_player_informations: Array[PlayerInformation],
    new_winning_side: Player.Side
) -> void:
    match_options = new_options
    player_informations = new_player_informations
    winning_side = new_winning_side

func _ready() -> void:
    # Error handling signals:
    SyncManager.sync_stopped.connect(_on_sync_stopped)
    SyncManager.sync_error.connect(_on_sync_error)
    multiplayer.multiplayer_peer.peer_disconnected.connect(_on_broken_connection)
    
    if player_informations[0].network_id != player_informations[1].network_id:        
        var producer_side = rematch_menus[0].get_path() if multiplayer.is_server() else rematch_menus[1].get_path()
        var receiver_side = rematch_menus[1].get_path() if multiplayer.is_server() else rematch_menus[0].get_path()
        SyncManager.message_serializer.produce_input_path = producer_side
        SyncManager.message_serializer.receive_input_path = receiver_side
    
    # Normal behavior signals:
    #SyncManager.sync_started.connect(post_selection_delay_timer.start.bind(POST_SELECTION_DURATION), CONNECT_ONE_SHOT)
    post_selection_delay_timer.timeout.connect(_start_new_game)
    
    if multiplayer.is_server():
        SyncManager.start()
        
    _init_display()
    _init_rematch_menu()


# INITIAL DISPLAY #
func _init_display():
    _decorate_for_win_or_loss(_is_winner_local())
    _set_results_box_display()

func _is_winner_local() -> bool:
    var is_player_local = player_informations.map(func(x): return x.network_id == multiplayer.get_unique_id())
    var is_winner_local: bool = false
    for i in is_player_local.size():
        if is_player_local[i] and i == winning_side:
            is_winner_local = true
            break
    return is_winner_local

func _decorate_for_win_or_loss(winner_local: bool) -> void:
    const victory_title_display := "Victory!"
    const defeat_title_display := "Defeat..."
    if winner_local:
        $UI/Title.text = victory_title_display
    else:
        $UI/Title.text = defeat_title_display

func _set_results_box_display() -> void:
    # character portrait thingy should do the heavy lifting of selecting the picture
    # should pass in a character spec & whether that player won or lost.
    assert(player_informations.size() == results_boxes.size())
    for i in player_informations.size():
        results_boxes[i].set_results(i == winning_side, player_informations[i])

# REMATCH LOGIC #
func _init_rematch_menu():
    assert(player_informations.size() == rematch_menus.size())
    for i in player_informations.size():
        rematch_menus[i].init_input_mapping(player_informations[i].input_mapping)
        rematch_menus[i].set_multiplayer_authority(player_informations[i].network_id)

func _start_new_game():
    SyncManager.stop()
    
    var gameplay = load("res://TestGameplay.tscn")
    var instantiated_map = gameplay.instantiate()
    instantiated_map.init_options(match_options)
    var win_records: Array[int] = [player_informations[0].number_of_wins, player_informations[1].number_of_wins]
    instantiated_map.init_wins_record(win_records)
    instantiated_map.p1_network_id = player_informations[0].network_id
    instantiated_map.p2_network_id = player_informations[1].network_id
    SceneSwitchUtil.change_scene(get_tree(), instantiated_map)

# NETWORK ISSUE HANDLING #
func _on_sync_error(_msg: String):
    # communicate that a fatal state mismatch occurred. 
    var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, DESYNC_ERROR_FORMAT)
    closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)
    
func _on_broken_connection(disconnected_peer_id: int):
    if disconnected_peer_id in player_informations.map(func(x): return x.network_id):
        _close_rollback_networking()
        var closed_signal: Signal = notification_window.notify_error(NETWORK_ERROR_TYPE, CONNECTION_LOST_ERROR_FORMAT)
        closed_signal.connect(_return_to_network_menu, CONNECT_ONE_SHOT)

func _close_rollback_networking():
    $PostSelectionDelay.stop()
    SyncManager.clear_peers()
    # Leaves godot high-level multiplayer connection intact.

func _return_to_network_menu() -> void:
    var main_menu_scene = SceneSwitchUtil.main_menu_scene.instantiate()
    SceneSwitchUtil.change_scene(get_tree(), main_menu_scene)

func _on_sync_stopped(reason: Disconnect.Reason):
    SyncManager.stop_logging()
    
    if reason == Disconnect.Reason.DESYNC:
        _on_sync_error("")
