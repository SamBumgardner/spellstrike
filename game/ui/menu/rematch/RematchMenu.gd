extends PanelContainer

const NO_SELECTION: int = -1

signal rematch
signal quit

@onready var rematch_button = $"%RematchOption"
@onready var quit_button = $"%QuitOption"
@onready var action_buffer = $ActionBuffer

@onready var ui_targets: Array = [rematch_button, quit_button]
var ui_signals: Array[Signal] = [rematch, quit]

#@onready var rematch_pressed: Signal = rematch_button.pressed
#@onready var quit_pressed: Signal = quit_button.pressed

var input_retriever: InputRetriever = InputRetriever.new()

var display_targeted_ui_index: int = -1
var hovered_ui_target: MenuOption = null:
    set(x):
        if hovered_ui_target != null and hovered_ui_target.state == MenuOption.OptionState.HOVERED:
            hovered_ui_target.state = MenuOption.OptionState.NORMAL
        hovered_ui_target = x
        if hovered_ui_target != null:
            hovered_ui_target.state = MenuOption.OptionState.HOVERED

var display_selected_ui_index = -1
var selected_ui_target: MenuOption = null:
    set(x):
        if selected_ui_target != null and selected_ui_target.state == MenuOption.OptionState.SELECTED:
            selected_ui_target.state = MenuOption.OptionState.NORMAL
        selected_ui_target = x
        if selected_ui_target != null:
            selected_ui_target.state = MenuOption.OptionState.SELECTED

# Stateful variables
var targeted_ui_index: int = 0
var selected_ui_index: int = NO_SELECTION
var network_process_enabled: bool = true

# INIT #
func init_input_mapping(new_input_mapping: Dictionary):
    input_retriever.input_ids = new_input_mapping

func _ready() -> void:
    add_to_group("network_sync")
    hovered_ui_target = rematch_button

# ACTIONS #
func _change_displayed_target(new_target_index) -> void:
    display_targeted_ui_index = new_target_index
    hovered_ui_target = ui_targets[display_targeted_ui_index]
    # TODO: Play sound effect

func _change_selected_target(new_selected_index) -> void:
    display_selected_ui_index = new_selected_index
    selected_ui_target = ui_targets[display_selected_ui_index]

func _move_selection(_action_buffer: ActionBuffer) -> void:
    #TODO: abstract this away by making ui_targets accept buffer & decide what the new target is.
    var backward_inputs = ['l', 'u']
    for input_key in backward_inputs:
        if _action_buffer.consume_just_pressed(input_key):
            targeted_ui_index -= 1
    
    var forward_inputs = ['r', 'd']
    for input_key in forward_inputs:
        if _action_buffer.consume_just_pressed(input_key):
            targeted_ui_index += 1
    
    targeted_ui_index = clampi(targeted_ui_index, 0, ui_targets.size() - 1)

func _check_selection(_action_buffer: ActionBuffer) -> bool:
    var selection_made: bool = false
    var confirm_inputs = ['a', 'b', 'c', 's']
    for input_key in confirm_inputs:
        if _action_buffer.consume_just_pressed(input_key):
            selection_made = true
            break
    return selection_made

func _make_selection() -> void:
    selected_ui_index = targeted_ui_index
    ui_signals[selected_ui_index].emit()

# PROCESS #
func _network_process(input: Dictionary) -> void:
    if not network_process_enabled:
        return
    
    if input.is_empty():
        input = InputRetriever.EMPTY
    
    action_buffer.push_frame(input)
    action_buffer.set_lookback_distance(ActionBuffer.QUEUE_LENGTH)
    if selected_ui_index == NO_SELECTION:
        _move_selection(action_buffer)
        if _check_selection(action_buffer):
            _make_selection()

func _process(_delta: float) -> void:
    if targeted_ui_index != display_targeted_ui_index:
        _change_displayed_target(targeted_ui_index)
    if selected_ui_index != display_selected_ui_index:
        _change_selected_target(selected_ui_index)
    
# ROLLBACK #
func _get_local_input() -> Dictionary:
    return input_retriever.retrieve_input()

func _predict_remote_input(old_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
    if ticks_since_real_input >= 5:
        return InputRetriever.EMPTY
    return old_input

func _save_state() -> Dictionary:
    return {
        'tui': targeted_ui_index
    }

func _load_state(state: Dictionary) -> void:
    targeted_ui_index = state['tui']
