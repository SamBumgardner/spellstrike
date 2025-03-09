class_name Postgame extends Control

const POST_SELECTION_DURATION = MatchOptions.ticks_per_second * 1

@onready var notification_window: Notification = $UI/Notification
const NETWORK_ERROR_TYPE: String = "NETWORK"
const DESYNC_ERROR_FORMAT: String = "Desync ocurred. Match has been cancelled.\rReturning to the network menu..."
const CONNECTION_LOST_ERROR_FORMAT: String = "Connection lost. Match has been cancelled.\rReturning to the network menu..."

@onready var post_selection_delay_timer: NetworkTimer = $PostSelectionDelay

var match_options: MatchOptions
var p1_network_id: int = 1
var p2_network_id: int = 1
var player_wins: Array[int] = [0, 0]

func init_options(new_options: MatchOptions) -> void:
    match_options = new_options

func init_wins_record(starting_wins: Array[int]) -> void:
    player_wins = starting_wins

func _ready() -> void:
    # Error handling signals:
    SyncManager.sync_stopped.connect(_on_sync_stopped)
    SyncManager.sync_error.connect(_on_sync_error)
    multiplayer.multiplayer_peer.peer_disconnected.connect(_on_broken_connection)
    
    # Normal behavior signals:
    SyncManager.sync_started.connect(post_selection_delay_timer.start.bind(POST_SELECTION_DURATION), CONNECT_ONE_SHOT)
    post_selection_delay_timer.timeout.connect(_start_new_game)

    if multiplayer.is_server():
        SyncManager.start()
    
func _start_new_game():
    SyncManager.stop()
    
    var gameplay = load("res://TestGameplay.tscn")
    var instantiated_map = gameplay.instantiate()
    instantiated_map.init_options(match_options)
    instantiated_map.init_wins_record(player_wins)
    instantiated_map.p1_network_id = p1_network_id
    instantiated_map.p2_network_id = p2_network_id
    SceneSwitchUtil.change_scene(get_tree(), instantiated_map)

# NETWORK ISSUE HANDLING #
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
