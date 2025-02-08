class_name InputHelper

static var EMPTY = 0

static func to_int(input_dict: Dictionary) -> int:
    # assumes all input dict fields are populated.
    var result = 0b00000000
    for key in Player.input_dict_keys:
        result = result << 1
        result = (result | input_dict[key])
    
    return result

static func to_dict(input_int: int) -> Dictionary:
    var result = {}
    var inverted_keys = Player.input_dict_keys.duplicate()
    inverted_keys.reverse()
    for key in inverted_keys:
        result[key] = input_int | 1
        input_int = input_int >> 1
    
    return result

