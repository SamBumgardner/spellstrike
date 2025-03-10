class_name InputRetriever extends RefCounted

const INPUT_KEYS = ["l", "r", "u", "d", "a", "b", "c", "s"]
const INPUT_FRIENDLY_NAMES = ["Left", "Right", "Up", "Down", "A", "B", "C", "Special"]

var control_type: ControlType = ControlType.KEYBOARD;
var device_id: int = 0;
var input_ids: Dictionary = DEFAULT_P1 # could store a dictionary of callables instead.

static var DEFAULT_P1 = {
    "l": [65], # A
    "r": [68], # D
    "u": [87], # W
    "d": [83], # S
    "a": [74], # J
    "b": [75], # K
    "c": [76], # L
    "s": [59], # ;
}

static var DEFAULT_P2 = {
    "l": [90], # Z
    "r": [67], # C
    "u": [86], # V
    "d": [88], # X
    "a": [78], # N
    "b": [77], # M
    "c": [188], # ,
    "s": [190], #.
}

static var DEFAULT_CONTROLLER = {
    "l": [0, 13], # Z
    "r": [0, 14], # C
    "u": [0, 11],
    "d": [0, 12],
    "a": [0, 2], # N
    "b": [0, 3], # M
    "c": [0, 10], # ,
    "s": [0, 0], #.
}

static var DEFAULT_CONTROLLER_2 = {
    "l": [1, 13], # Z
    "r": [1, 14], # C
    "u": [0, 11],
    "d": [0, 12],
    "a": [1, 2], # N
    "b": [1, 3], # M
    "c": [1, 10], # ,
    "s": [1, 0], #.
}

const EMPTY := {
    "l": 0,
    "r": 0,
    "u": 0,
    "d": 0,
    "a": 0,
    "b": 0,
    "c": 0,
    "s": 0,
}

func _init(mapping: Dictionary = DEFAULT_P1):
    input_ids = mapping

func retrieve_input() -> Dictionary:
    var input_retrieve_method: Callable
    if control_type == ControlType.KEYBOARD:
        input_retrieve_method = Input.is_physical_key_pressed
    elif control_type == ControlType.JOY:
        input_retrieve_method = Input.is_joy_button_pressed

    var result: Dictionary = EMPTY.duplicate()
    for key in result.keys():
        var size = input_ids[key].size()
        if size == 1:
            input_retrieve_method = Input.is_physical_key_pressed
            result[key] = 1 if input_retrieve_method.callv(input_ids[key]) else 0
        elif size == 2:
            input_retrieve_method = Input.is_joy_button_pressed
            result[key] = 1 if input_retrieve_method.callv(input_ids[key]) else 0
        else:
            input_retrieve_method = Input.get_joy_axis
            var axis_value = input_retrieve_method.callv(input_ids[key].slice(0, 2))
            result[key] = 1 if sign(axis_value) == sign(input_ids[key][2]) and abs(axis_value) >= abs(input_ids[key][2]) else 0
    
    return result

enum ControlType {
    KEYBOARD = 0,
    JOY = 1
}
