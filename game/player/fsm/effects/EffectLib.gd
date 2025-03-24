# A place to hold static 'Effect' methods referenced by PhaseEffect.gd
#  FsmState will call these methods during 'process', allowing us to use data to define state
#  actions. 
class_name EffectLib

enum Effect {
    NONE = -1,
    NORMAL_WALK = 0,
    STOPPED_TO_IDLE = 1,
    START_WALK = 2,
    START_ACTION = 3,
    DEBUG_LOG = 4,
    SET_VELOCITY = 5,
    CHECK_HITSTUN_OVER = 6,
    DECAYING_PUSHBACK = 7,
    VELOCITY_DECAY_NATURAL = 8,
    PLAY_SOUND = 9,
    MATCH_SCALE_TO_FACING = 10,
    EXPIRE_OWNER = 11,
    REQUEST_PROJECTILE = 12,
    MODIFY_SPECIAL_STOCK = 13,
    FORCE_CHANGE_STATE = 14,
    CHANGE_HP = 15,
}

static var methods := {
    Effect.NORMAL_WALK: walk,
    Effect.STOPPED_TO_IDLE: stopped_to_idle,
    Effect.START_WALK: start_walk,
    Effect.START_ACTION: start_action,
    Effect.DEBUG_LOG: debug_log,
    Effect.SET_VELOCITY: set_velocity,
    Effect.CHECK_HITSTUN_OVER: check_hitstun_over,
    Effect.DECAYING_PUSHBACK: decaying_pushback,
    Effect.VELOCITY_DECAY_NATURAL: velocity_decay_natural,
    Effect.PLAY_SOUND: play_sound,
    Effect.MATCH_SCALE_TO_FACING: match_scale_to_facing,
    Effect.EXPIRE_OWNER: expire_owner,
    Effect.REQUEST_PROJECTILE: request_projectile,
    Effect.MODIFY_SPECIAL_STOCK: modify_special_stock,
    Effect.FORCE_CHANGE_STATE: force_change_state,
    Effect.CHANGE_HP: change_hp,
}


# HELPER #
static func _get_move_direction(input_buffer: ActionBuffer) -> int:
    var movement_direction: int = 0
    if input_buffer.is_pressed("l"):
        movement_direction -= 1
    if input_buffer.is_pressed("r"):
        movement_direction += 1
    
    return movement_direction

# EFFECT #
static func walk(owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int) -> Player.State:
    var movement_direction = _get_move_direction(input_buffer)
    var walking_forward = Player.get_side_scale(owner.facing_direction) == movement_direction
    var current_top_speed = owner.walk_speed if walking_forward else owner.back_walk_speed

    owner.velocity = clamp(
        owner.velocity + owner.walk_accel * movement_direction,
        -1 * (current_top_speed),
        current_top_speed)
    
    return Player.State.NONE

static func stopped_to_idle(owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int) -> Player.State:
    var movement_direction = _get_move_direction(input_buffer)
    
    if movement_direction == 0:
        if owner.velocity > 0:
            owner.velocity = max(0, owner.velocity - owner.walk_drag)
        if owner.velocity < 0:
            owner.velocity = min(0, owner.velocity + owner.walk_drag)
    
    return Player.State.IDLE if owner.velocity == 0 else Player.State.NONE

static func start_walk(_owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int) -> Player.State:
    var movement_direction = _get_move_direction(input_buffer)
    
    return Player.State.WALK if movement_direction != 0 else Player.State.NONE

static func start_action(owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int, input_to_state_mapping: Dictionary, attack_hit_required: bool) -> Player.State:
    if attack_hit_required and not owner.attack_hit:
        return Player.State.NONE
    for key in input_to_state_mapping.keys():
        if input_buffer.consume_just_pressed(key):
            return input_to_state_mapping[key]
    
    return Player.State.NONE

static func debug_log(_owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, message: String) -> Player.State:
    print_debug(message)
    return Player.State.NONE

static func set_velocity(owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int, new_velocity: int = 0, consider_input: bool = false) -> Player.State:
    var movement_direction = int(owner.scale.x) if not consider_input else _get_move_direction(input_buffer)
    
    owner.velocity = new_velocity * movement_direction
    return Player.State.NONE

static func check_hitstun_over(owner: Player, _input_buffer: ActionBuffer, ticks_in_state: int) -> Player.State:
    if owner.hitstun_duration < ticks_in_state:
        return Player.State.IDLE
    else:
        return Player.State.NONE

static func decaying_pushback(owner: Player, _input_buffer: ActionBuffer, ticks_in_state: int) -> Player.State:
    if owner.status == Player.Status.HITSTUN:
        var base_decay = (owner.pushback / min(owner.hitstun_duration, 10) * ticks_in_state)
        var remainder = owner.pushback % min(owner.hitstun_duration, 10)
        base_decay += min(ticks_in_state, remainder)

        var clamped_decay = max(owner.pushback - base_decay, 0) if owner.pushback >= 0 else min(owner.pushback - base_decay, 0)

        owner.pushback_velocity = owner.scale.x * -1 * clamped_decay
    #if ticks_in_state % 3 != 0:
        #owner.pushback = max(owner.pushback - 2, 0)
        
    return Player.State.NONE

static func velocity_decay_natural(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, rate: int) -> Player.State:
    if owner.velocity > 0:
        owner.velocity = max(0, owner.velocity - rate)
    elif owner.velocity < 0:
        owner.velocity = min(0, owner.velocity + rate)

    return Player.State.NONE

static func play_sound(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, sound_effect: AudioStream) -> Player.State:
    SyncManager.play_sound("%s_effectLib_%s" % [owner.name, sound_effect.resource_name], sound_effect)

    return Player.State.NONE

static func match_scale_to_facing(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int) -> Player.State:
    owner.scale.x = Player.get_side_scale(owner.facing_direction)

    return Player.State.NONE

static func expire_owner(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int) -> Player.State:
    owner.expire()

    return Player.State.NONE

static func request_projectile(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, projectile_type: int) -> Player.State:
    owner.request_projectile.emit(projectile_type, owner)

    return Player.State.NONE

static func modify_special_stock(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, special_change_amt: int) -> Player.State:
    owner.special_uses += special_change_amt

    return Player.State.NONE

# Warning: probably only use this on transition in or transition out if you need a transitioanl switcheroo.
static func force_change_state(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, new_state: int) -> Player.State:
    owner.fsm.force_change_state(new_state)

    return Player.State.NONE

static func change_hp(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, health_change_amt: int) -> Player.State:
    owner.health = clampi(owner.health + health_change_amt, 1, owner.max_health)
    return Player.State.NONE
