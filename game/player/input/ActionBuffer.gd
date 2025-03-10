class_name ActionBuffer extends Node

# for each input, track how many frames ago it was pressed. 

# could use the circular queue again. Head is the current index, buttons being pressed get set to it. 
# When head advances, any buttons that match its value are forgotten.

# needs to implement "consume" method to use up an input from the buffer.

const action_indices: Dictionary = {
    'a' = 0,
    'b' = 1,
    'c' = 2,
    's' = 3,
    'l' = 4,
    'r' = 5,
    'u' = 6,
    'd' = 7
}

const QUEUE_LENGTH: int = 8
const NOT_PRESSED_INDEX: int = QUEUE_LENGTH

# stateful variables, must be tracked for rollback
var last_pressed_indexes: Array
var head: int = 0
var previous_frame_inputs: Dictionary = InputRetriever.EMPTY

# refreshed every frame, should be safe to leave untracked.
var current_frame_inputs: Dictionary
var valid_lookback_indices: Array
var current_lookback: int = 1

func _init():
    last_pressed_indexes = []
    last_pressed_indexes.resize(action_indices.keys().size())
    last_pressed_indexes.fill(NOT_PRESSED_INDEX)

    valid_lookback_indices = []
    valid_lookback_indices.resize(QUEUE_LENGTH + 1)
    valid_lookback_indices.fill(0)

func _ready():
    add_to_group("network_sync")

# Assume that action buttons will be 1 for "just pressed" and 0 otherwise.
# TODO: Keep in mind this will probably need to refactor if the actions we want to track grows more complex.
func push_frame(new_input: Dictionary) -> void:
    current_frame_inputs = new_input
    var just_pressed_inputs = generate_just_pressed_input(previous_frame_inputs, current_frame_inputs)

    head = (head + 1) % QUEUE_LENGTH
    # overwrite newly entered buffered input information with newly identified state.
    for input_key in action_indices:
        if just_pressed_inputs[input_key] == 1:
            last_pressed_indexes[action_indices[input_key]] = head
        elif last_pressed_indexes[action_indices[input_key]] == head:
            last_pressed_indexes[action_indices[input_key]] = NOT_PRESSED_INDEX
    
    previous_frame_inputs = new_input

static func generate_just_pressed_input(previous_input: Dictionary, new_input: Dictionary) -> Dictionary:
    var result = {}
    # Turn actions in dictionary to "just pressed" values (will be 0 if held)
    for input_key in new_input.keys():
        result[input_key] = new_input[input_key] & (new_input[input_key] ^ previous_input[input_key])
    return result

func set_lookback_distance(lookback_distance: int = 0) -> void:
    # figure out which indices should be "on" based on lookback distance.
    var current_distance = 0
    while current_distance < QUEUE_LENGTH:
        var lookback_index: int = head - current_distance + (0 if current_distance <= head else QUEUE_LENGTH)
        valid_lookback_indices[lookback_index] = 1 if current_distance <= lookback_distance else 0
        current_distance += 1

func is_pressed(input_key: String) -> int:
    return current_frame_inputs[input_key]

func consume_just_pressed(input_key: String) -> int:
    var result: int = 0
    var action_index = action_indices[input_key]
    result = valid_lookback_indices[last_pressed_indexes[action_index]]
    last_pressed_indexes[action_index] = NOT_PRESSED_INDEX
    return result

func _save_state() -> Dictionary:
    return {
        'lpi': last_pressed_indexes.duplicate(),
        'h': head,
        'pfi': InputHelper.to_int(previous_frame_inputs)
    }

func _load_state(state: Dictionary) -> void:
    last_pressed_indexes = state['lpi']
    head = state['h']
    previous_frame_inputs = InputHelper.to_dict(state['pfi'])
