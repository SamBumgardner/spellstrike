class_name RandomCpuInputRetriever extends InputRetriever

const ATTACK_CHANCE = .01
const ATTACK_DELAY = 1
const MOVE_DELAY_MIN = .25
const MOVE_DELAY_MAX = 1

var remaining_attack_delay: float = 0

var saved_directions: Dictionary = {"l": 0, "r": 0}
var remaining_move_choice_delay: float = 0

func retrieve_input() -> Dictionary:
    var result = EMPTY.duplicate()

    if remaining_move_choice_delay <= 0:
        saved_directions = {"l": randi() % 2, "r": randi() % 2}
        remaining_move_choice_delay = randf_range(MOVE_DELAY_MIN, MOVE_DELAY_MAX)

    for key in result:
        if key in saved_directions.keys():
            result[key] = saved_directions[key]
        else:
            if remaining_attack_delay <= 0 and randf() < ATTACK_CHANCE:
                result[key] = 1
                remaining_attack_delay = ATTACK_DELAY
            else:
                result[key] = 0
    
    return result

func _process(delta: float):
    if remaining_attack_delay > 0:
        remaining_attack_delay -= delta

    if remaining_move_choice_delay > 0:
        remaining_move_choice_delay -= delta
