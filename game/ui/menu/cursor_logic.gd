class_name CursorLogic extends Node

signal selection_changed(new_target_ui: Control)
signal status_changed(new_status: Status)

enum Status {
    ACTIVE = 0,
    SELECTED = 1,
    DISABLED = 2,
    GONE = 3,
}

var attached_controller_menu: AbstractControllerMenu
var input_retriever: InputRetriever
@onready var action_buffer: ActionBuffer = $ActionBuffer

var network_process_enabled: bool = true
var cursor_status: Status:
    set(x):
        if cursor_status != x:
            cursor_status = x
            status_changed.emit(cursor_status)

var current_target_ui: Control:
    set(x):
        if current_target_ui != x:
            current_target_ui = x
            selection_changed.emit(current_target_ui)

func initialize(menu: AbstractControllerMenu, input: InputRetriever, start_status: Status) -> void:
    attached_controller_menu = menu
    input_retriever = input
    
    cursor_status = start_status
    current_target_ui = attached_controller_menu.get_initial_element()

func _ready() -> void:
    add_to_group("network_sync")

func _network_process(input: Dictionary) -> void:
    if not network_process_enabled:
        return

    action_buffer.push_frame(input)
    action_buffer.set_lookback_distance(ActionBuffer.QUEUE_LENGTH)

    if cursor_status == Status.ACTIVE:
        current_target_ui = attached_controller_menu.move_selection(current_target_ui, action_buffer)
    
    if cursor_status not in [Status.DISABLED, Status.GONE]:
        attached_controller_menu.act_on_selection(current_target_ui, action_buffer)

func _get_local_input() -> Dictionary:
    return input_retriever.retrieve_input()

func _predict_remote_input(_old_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
    return InputRetriever.EMPTY

func _save_state() -> Dictionary:
    return {
        'npe': network_process_enabled,
        'acm': attached_controller_menu,
        'cs': cursor_status,
        'cti': current_target_ui.get_path(),
    }

func _load_state(state: Dictionary) -> void:
    network_process_enabled = state['npe']
    attached_controller_menu = state['acm']
    cursor_status = state['cs']
    current_target_ui = get_node(state['ctu'])
