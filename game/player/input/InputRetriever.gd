class_name InputRetriever extends RefCounted

var control_type: ControlType = ControlType.KEYBOARD;
var device_id: int = 0;
var input_ids: Dictionary = DEFAULT_P1 # could store a dictionary of callables instead.

static var DEFAULT_P1 = {
    "l": [65], # A
    "r": [68], # D
    "a": [74], # J
    "b": [75], # K
    "c": [76], # L
    "s": [59], # ;
}

static var DEFAULT_P2 = {
    "l": [90], # Z
    "r": [67], # C
    "a": [78], # N
    "b": [77], # M
    "c": [188], # ,
    "s": [190], # .
}

static var DEFAULT_CONTROLLER = {
    "l": [0, 13], # Z
    "r": [0, 14], # C
    "a": [0, 2], # N
    "b": [0, 3], # M
    "c": [0, 10], # ,
    "s": [0, 0], # .
}

static var DEFAULT_CONTROLLER_2 = {
    "l": [1, 13], # Z
    "r": [1, 14], # C
    "a": [1, 2], # N
    "b": [1, 3], # M
    "c": [1, 10], # ,
    "s": [1, 0], # .
}

const EMPTY := {
    "l": 0,
    "r": 0,
    "a": 0,
    "b": 0,
    "c": 0,
    "s": 0,
}

func retrieve_input() -> Dictionary:
    var input_retrieve_method: Callable
    if control_type == ControlType.KEYBOARD:
        input_retrieve_method = Input.is_physical_key_pressed
    elif control_type == ControlType.JOY:
        input_retrieve_method = Input.is_joy_button_pressed

    var result: Dictionary = EMPTY.duplicate()
    for key in result.keys():
        result[key] = 1 if input_retrieve_method.callv(input_ids[key]) else 0
    
    return result

enum ControlType {
    KEYBOARD = 0,
    JOY = 1
}
