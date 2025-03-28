class_name InputHelper

static var EMPTY = 0

static func to_int(input_dict: Dictionary) -> int:
    # assumes all input dict fields are populated.
    var result = 0b00000000
    for key in InputRetriever.INPUT_KEYS:
        result = result << 1
        result = (result | input_dict[key])
    
    return result

static func to_dict(input_int: int) -> Dictionary:
    var result = {}
    var inverted_keys = InputRetriever.INPUT_KEYS.duplicate()
    inverted_keys.reverse()
    for key in inverted_keys:
        result[key] = input_int & 0b00000001
        input_int = input_int >> 1
    
    return result
