class_name AttackData extends Resource

@export var damage: int
@export var hitstun: int
@export var hitstop: int
@export var pushback: int
@export var sound_effect: AudioStream
var num_hits: int = 1

static func combine_overlapping_attacks(accumulator_array: Array, real_array: Array) -> Array:
    var accumulator = accumulator_array[0]
    var real = real_array[0]
    var real_owner = real_array[1]

    var acc_total = accumulator.hitstun + accumulator.hitstop
    var real_total = real.hitstun + real.hitstop
    if real_total > acc_total:
        accumulator.hitstop = real.hitstop
        accumulator.hitstun = real.hitstun
        accumulator.pushback = real.pushback
        accumulator_array[1] = real_owner
    elif real_total == acc_total:
        if real.hitstun > accumulator.hitstun:
            accumulator.hitstop = real.hitstop
            accumulator.hitstun = real.hitstun
            accumulator.pushback = real.pushback
            accumulator_array[1] = real_owner
    
    accumulator.damage += real.damage
    accumulator.num_hits += real.num_hits

    return accumulator_array
