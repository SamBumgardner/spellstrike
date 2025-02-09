# A place to hold static 'Effect' methods referenced by PhaseEffect.gd
#  FsmState will call these methods during 'process', allowing us to use data to define state
#  actions. 
class_name EffectLib

enum Effect { 
    NONE = -1,
    NORMAL_WALK = 0,
    STOPPED_TO_IDLE = 1,
    START_WALK = 2,
}

static var methods := {
    Effect.NORMAL_WALK: walk,
    Effect.STOPPED_TO_IDLE: stopped_to_idle,
    Effect.START_WALK: start_walk,
}

static func walk(owner: Player, input: Dictionary, _ticks_in_state: int) -> Player.State:
    var movement_direction: int = 0
    if input["l"]:
        movement_direction -= 1
    if input["r"]:
        movement_direction += 1

    owner.velocity = clamp(
        owner.velocity + owner.walk_accel * movement_direction,
        -owner.walk_speed,
        owner.walk_speed)
    
    return Player.State.NONE

static func stopped_to_idle(owner: Player, input: Dictionary, _ticks_in_state: int) -> Player.State:
    var movement_direction: int = 0
    if input["l"]:
        movement_direction -= 1
    if input["r"]:
        movement_direction += 1
    
    if movement_direction == 0:
        if owner.velocity > 0:
            owner.velocity = max(0, owner.velocity - owner.walk_drag)
        if owner.velocity < 0:
            owner.velocity = min(0, owner.velocity + owner.walk_drag)
    
    return Player.State.IDLE if owner.velocity == 0 else Player.State.NONE

static func start_walk(_owner: Player, input: Dictionary, _ticks_in_state: int) -> Player.State:
    var movement_direction: int = 0
    if input["l"]:
        movement_direction -= 1
    if input["r"]:
        movement_direction += 1
    
    return Player.State.WALK if movement_direction != 0 else Player.State.NONE
