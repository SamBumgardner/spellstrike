class_name InputRetriever extends RefCounted

var control_type: ControlType = ControlType.KEYBOARD;
var device_id: int = 0;
var input_ids: Dictionary = { # could store a dictionary of callables instead.
	"l": 65, # A
	"r": 68, # D
	"a": 74, # J
	"b": 75, # K
	"c": 76, # L
	"s": 59, # ;
}


func retrieve_input() -> Dictionary: 
	var input_retrieve_method: Callable
	if control_type == ControlType.KEYBOARD:
		input_retrieve_method = Input.is_physical_key_pressed
	elif control_type == ControlType.JOY:
		input_retrieve_method = Input.is_joy_button_pressed

	var result: Dictionary = {
		"l": 0,
		"r": 0,
		"a": 0,
		"b": 0,
		"c": 0,
		"s": 0,
	}

	for key in result.keys():
		result[key] = 1 if input_retrieve_method.call(input_ids[key]) else 0
	
	return result

static func empty_input() -> Dictionary:
	return {
		"l": 0,
		"r": 0,
		"a": 0,
		"b": 0,
		"c": 0,
		"s": 0,
	}

enum ControlType {
	KEYBOARD = 0,
	JOY = 1
}
