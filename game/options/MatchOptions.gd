class_name MatchOptions extends RefCounted

const separate_distance: int = 10

const ticks_per_second: int = 60
const default_seconds_per_round: int = 60
const default_ticks_per_round: int = default_seconds_per_round * ticks_per_second # ticks_per_second * default_seconds_per_round

const default_rounds_to_win: int = 2

var input_retrievers: Array

func _init(new_input_retrievers):
    input_retrievers = new_input_retrievers

static func generate_default() -> MatchOptions:
    return MatchOptions.new(
        [InputRetriever.new(InputMappingManager.p1_input_mapping), InputRetriever.new(InputMappingManager.p2_input_mapping)]
    )
