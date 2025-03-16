class_name CharacterSelect extends Control

const POST_SELECTION_DURATION: int = int(MatchOptions.ticks_per_second * .5)

@onready var notification_window: Notification = $UI/Notification
const NETWORK_ERROR_TYPE: String = "NETWORK"
const DESYNC_ERROR_FORMAT: String = "Desync ocurred. Match has been cancelled.\rReturning to the network menu..."
const CONNECTION_LOST_ERROR_FORMAT: String = "Connection lost. Match has been cancelled.\rReturning to the network menu..."

@onready var character_options: CharacterOptions = $UI/CharacterOptions
@onready var cursor_logics: Array[CursorLogic] = [$UI/CharacterOptions/CursorLogic, $UI/CharacterOptions/CursorLogic2]
@onready var frame_cursors: Array[FrameCursor] = [$UI/CharacterOptions/FrameCursor, $UI/CharacterOptions/FrameCursor2]
@onready var player_selections: Array[PlayerSelection] = [$UI/PlayerSelections/PlayerSelection, $UI/PlayerSelections/PlayerSelection2]

@onready var post_selection_delay_timer: NetworkTimer = $PostSelectionDelay
var match_options: MatchOptions
var player_informations: Array[PlayerInformation]
var network_ids: Array

# Stateful variables
var number_of_selections_confirmed: int = 0

func init(
    new_options: MatchOptions,
    new_player_informations: Array[PlayerInformation]
) -> void:
    match_options = new_options
    player_informations = new_player_informations
    network_ids = player_informations.map(func(x): return x.network_id)

func _ready() -> void:
    add_to_group("network_sync")
    
    for i in Player.Side.values():
        cursor_logics[i].selection_changed.connect(frame_cursors[i]._on_selection_changed)
        cursor_logics[i].status_changed.connect(frame_cursors[i]._on_status_changed)
        cursor_logics[i].initialize(character_options, CursorLogic.Status.ACTIVE, i, player_informations[i])
        cursor_logics[i].set_multiplayer_authority(player_informations[i].network_id)
    
    character_options.character_selected.connect(_on_character_selected)
    character_options.selection_canceled.connect(_on_selection_cancelled)
    character_options.character_selection_moved.connect(_on_character_selection_moved)

    # set up initial view
    for side in Player.Side.values():
        player_selections[side].preview_character(character_options.get_initial_character(side, player_informations[side]))
        player_selections[side].init(player_informations[side])

    _network_setup()

    if multiplayer.is_server():
        get_tree().create_timer(.5).timeout.connect(SyncManager.start, CONNECT_ONE_SHOT)
    
    # SyncManager.start_logging("user://rollback_logfile_%s" % randi())


func _network_setup():
    if player_informations[0].network_id != player_informations[1].network_id:
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/RPCNetworkAdaptor.gd").new())

        for id in network_ids:
            if id != multiplayer.get_unique_id() and id not in SyncManager.peers:
                SyncManager.add_peer(id)
        
        var producer_side = cursor_logics[0].get_path() if multiplayer.is_server() else cursor_logics[1].get_path()
        var receiver_side = cursor_logics[1].get_path() if multiplayer.is_server() else cursor_logics[0].get_path()
        SyncManager.message_serializer.produce_input_path = producer_side
        SyncManager.message_serializer.receive_input_path = receiver_side
        
        SyncManager.sync_stopped.connect(_on_sync_stopped)
        SyncManager.sync_error.connect(_on_sync_error)
        multiplayer.multiplayer_peer.peer_disconnected.connect(_on_broken_connection)
    
    else:
        SyncManager.set_network_adaptor(preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd").new())
    
    post_selection_delay_timer.timeout.connect(_start_new_game)
    # TODO: Allow quitting from this menu
    # quit_delay_timer.timeout.connect(_return_to_network_menu)

func _on_character_selection_moved(acting_side: Player.Side, character_spec: CharacterSpec) -> void:
    player_selections[acting_side].preview_character(character_spec)

func _on_character_selected(acting_side: Player.Side, character_spec: CharacterSpec) -> void:
    if cursor_logics[acting_side].cursor_status == CursorLogic.Status.ACTIVE:
        cursor_logics[acting_side].cursor_status = CursorLogic.Status.SELECTED
        player_selections[acting_side].select_character(character_spec)
        player_informations[acting_side].character_spec = character_spec
        _on_selection_confirmed()
    
func _on_selection_cancelled(acting_side: Player.Side, character_spec: CharacterSpec) -> void:
    if cursor_logics[acting_side].cursor_status == CursorLogic.Status.SELECTED:
        cursor_logics[acting_side].cursor_status = CursorLogic.Status.ACTIVE
        player_selections[acting_side].preview_character(character_spec)
        player_informations[acting_side].character_spec = null
        _on_confirmation_cancelled()


# CONFIRMATION & NEXT STATE HANDLING #
func _on_selection_confirmed():
    number_of_selections_confirmed += 1
    if number_of_selections_confirmed >= player_informations.size():
        post_selection_delay_timer.start(POST_SELECTION_DURATION)
        _set_cursor_logic_processing(false)

func _set_cursor_logic_processing(processing_enabled: bool) -> void:
    for cursor_logic: CursorLogic in cursor_logics:
        cursor_logic.network_process_enabled = processing_enabled

func _on_confirmation_cancelled():
    number_of_selections_confirmed -= 1
    if number_of_selections_confirmed < player_informations.size():
        post_selection_delay_timer.stop()
        _set_cursor_logic_processing(true)

func _start_new_game():
    SyncManager.stop_logging()
    SyncManager.stop()
    
    var gameplay = load("res://TestGameplay.tscn")
    var instantiated_map = gameplay.instantiate()
    instantiated_map.init(match_options, player_informations)
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
    SyncManager.stop_logging()
    SyncManager.stop()
    SyncManager.clear_peers()
    # Leaves godot high-level multiplayer connection intact.

func _return_to_network_menu() -> void:
    _close_rollback_networking()
    var main_menu_scene = load("res://network/main.tscn").instantiate()
    SceneSwitchUtil.change_scene(get_tree(), main_menu_scene)

func _on_sync_stopped(reason: Disconnect.Reason):
    SyncManager.stop_logging()
    
    if reason == Disconnect.Reason.DESYNC:
        _on_sync_error("")


# ROLLBACK #
func _save_state() -> Dictionary:
    return {
        'nsc': number_of_selections_confirmed
    }

func _load_state(state: Dictionary) -> void:
    number_of_selections_confirmed = state['nsc']
