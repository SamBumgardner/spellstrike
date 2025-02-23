class_name AttackData extends Resource

var attack_id: int
@export var damage: int
@export var hitstun: int
@export var hitstop: int
@export var pushback: int
@export var sound_effect: AudioStream
var num_hits: int = 1

static func combine_overlapping_attacks(accumulator: AttackData, real: AttackData) -> AttackData:
    var acc_total = accumulator.hitstun + accumulator.hitstop
    var real_total = real.hitstun + real.hitstop
    if real_total > acc_total:
        accumulator.hitstop = real.hitstop
        accumulator.hitstun = real.hitstun
        accumulator.pushback = real.pushback
    elif real_total == acc_total:
        if real.hitstun > accumulator.hitstun:
            accumulator.hitstop = real.hitstop
            accumulator.hitstun = real.hitstun
            accumulator.pushback = real.pushback
    
    accumulator.damage += real.damage
    accumulator.num_hits += real.num_hits

    return accumulator
