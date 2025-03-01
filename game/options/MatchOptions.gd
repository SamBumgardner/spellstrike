class_name MatchOptions extends RefCounted

const separate_distance: int = 10

var input_retrievers: Array

func _init(new_input_retrievers):
    input_retrievers = new_input_retrievers

static func generate_default() -> MatchOptions:
    return MatchOptions.new(
        [InputRetriever.new(InputMappingManager.p1_input_mapping), InputRetriever.new(InputMappingManager.p2_input_mapping)]
    )
