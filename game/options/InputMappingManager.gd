# Singleton for defining player input mappings across the whole game
class_name InputMappingManager extends RefCounted

static var p1_input_mapping = InputRetriever.DEFAULT_P1
static var p2_input_mapping = InputRetriever.DEFAULT_P2

static func get_all_mappings() -> Dictionary:
    return {
        "p1": p1_input_mapping,
        "p2": p2_input_mapping,
    }

static func load_all_mappings(mappings) -> void:
    if typeof(mappings) == TYPE_DICTIONARY:
        p1_input_mapping = mappings["p1"]
        p2_input_mapping = mappings["p2"]
