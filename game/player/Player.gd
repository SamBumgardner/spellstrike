class_name Player extends Node2D

signal player_processing_finished

# State Dictionary:
    # x
    # y
    # t - team (Side enum)
    # pi - previous input (int, bitwise flags)
    # c - character (int, corresponds to enum)
    # hp - remaining health (int)
    # s - status (int, corresponds to enum)
    # fs - fsm state
    # ft - number of ticks spent in current fsm state
    # hs - total hitstop duration (usually 0)
    # hst - current hitstop tick
    # hsu - hitstun duration
    # pb - pushback
    # v - velocity
    # a - attack id
    # hb - hit by
    # 

const input_dict_keys = ['l', 'r', 'a', 'b', 'c', 's']

@onready var hurtbox_pool: Area2D = $HurtboxPool
@onready var hurtboxes := hurtbox_pool.get_children()
@onready var hitbox_pool: Area2D = $HitboxPool
@onready var hitboxes := hitbox_pool.get_children()

# composed utils
var input_retriever: InputRetriever
var fsm: Fsm

# TODO: move these to character spec
const walk_speed: int = 5
const walk_accel: int = 5
const walk_drag: int = 2

# Custom state variables
var team: Side
var character: Characters
var health: int
var velocity: int

var previous_input: int
var status: Status

var hitstop_duration: int
var current_hitstop_tick: int

var hitstun_duration: int
var pushback: int

var attack_id: int
var hit_by: Dictionary

# Stateless variables: refresh every frame
var current_attack_data: AttackData

#########
# SETUP #
#########

func _init():
    input_retriever = InputRetriever.new()
    fsm = Fsm.new()
    fsm.owner = self

func _ready():
    add_to_group("network_sync")
    _initialize_collision_shapes(hurtboxes)
    _initialize_collision_shapes(hitboxes)

func _initialize_collision_shapes(collision_shapes: Array) -> void:
    for collision_shape in collision_shapes:
        collision_shape.shape = RectangleShape2D.new()

func set_hurtboxes(rectangleSpecs: Array[RectangleSpec]) -> void:
    _set_collision_boxes(hurtboxes, rectangleSpecs)

func get_hurtboxes() -> Array:
    return hurtboxes.filter(func(x): return not x.disabled)

func get_hitboxes() -> Array:
    return hitboxes.filter(func(x): return not x.disabled)

func set_hitboxes(rectangleSpecs: Array[RectangleSpec], attack_data: AttackData, new_attack: bool) -> void:
    _set_collision_boxes(hitboxes, rectangleSpecs)
    current_attack_data = attack_data
    if new_attack:
        attack_id += 1

func _set_collision_boxes(collisionBoxes: Array, rectangleSpecs: Array[RectangleSpec]) -> void:
    assert(collisionBoxes.size() >= rectangleSpecs.size(), "cannot specify more than %d rectangles" % collisionBoxes.size())
    for i in collisionBoxes.size():
        if i < rectangleSpecs.size():
            collisionBoxes[i].disabled = false
            collisionBoxes[i].visible = true
            collisionBoxes[i].shape.size.x = rectangleSpecs[i].width
            collisionBoxes[i].shape.size.y = rectangleSpecs[i].height
            collisionBoxes[i].position.x = rectangleSpecs[i].x_offset
            collisionBoxes[i].position.y = rectangleSpecs[i].y_offset
        else:
            collisionBoxes[i].disabled = true
            collisionBoxes[i].visible = false
    
    
########################
# RESOLVE INTERACTIONS #
########################

func active_hurtbox_hit(enemy_attack_areas: Array) -> Array[bool]:
    # Expect nested type: Array[Array[CollisionShape2D]]
    var hits: Array[bool] = []
    var my_hurtboxes = get_hurtboxes()

    for attack_area_shapes in enemy_attack_areas:
        var collided: bool = false
        # compare each hitbox / hurtbox combination until overlap is found
        for hitbox in attack_area_shapes:
            for hurtbox in my_hurtboxes:
                collided = overlapped(hitbox, hurtbox) #TODO: replace with actual collision resolution method
                if collided:
                    break;
            if collided:
                break;
        hits.append(collided)

    # return bool values indicating what shapes hit me. Up to caller to act on that information.
    return hits

static func overlapped(a: CollisionShape2D, b: CollisionShape2D) -> bool:
    var x_overlap = compare_dimension(
        a.global_position.x - a.shape.size.x / 2,
        b.global_position.x - b.shape.size.x / 2,
        a.shape.size.x,
        b.shape.size.x
    )

    if not x_overlap:
        return false
    
    var y_overlap = compare_dimension(
        a.global_position.y - a.shape.size.y / 2,
        b.global_position.y - b.shape.size.y / 2,
        a.shape.size.y,
        b.shape.size.y
    )

    return y_overlap

static func compare_dimension(start1: int, start2: int, length1: int, length2: int) -> bool:
    var overlap := false
    if start1 == start2:
        overlap = true
    elif start1 < start2:
        if start1 + length1 > start2:
            overlap = true
    elif start2 < start1:
        if start2 + length2 > start1:
            overlap = true
    
    return overlap

func perform_hit(attack_data: AttackData) -> void:
    # put self in hitstop for frames based on own attack data (which is fed in here)
    hitstop_duration = attack_data.hitstop
    current_hitstop_tick = 0

func receive_hit(attack_data: AttackData) -> void:
    # do whatever steps are neeed to apply attack data (damage received, add hitstop, change state)
    # add attacker id to map of things you've been hit by, value is attack's numeric id.
    hitstun_duration = attack_data.hitstun
    hitstop_duration = attack_data.hitstop
    current_hitstop_tick = 0
    pushback = attack_data.pushback
    health -= attack_data.damage

    # force player to jump to hurt state.
    fsm.force_change_state(State.HITSTUN)
    

##########################
# ROLLBACK IMPLEMNTATION #
##########################
func _save_state() -> Dictionary:
    return {
        'x': position.x,
        'y': position.y,
        't': team,
        'pi': previous_input,
        'c': character,
        'hp': health,
        's': status,
        'fs': fsm.state,
        'ft': fsm.ticks_in_state,
        'hs': hitstop_duration,
        'hst': current_hitstop_tick,
        'hsu': hitstun_duration,
        'pb': pushback,
        'v': velocity,
        'a': attack_id,
        'hb': var_to_bytes(hit_by),
    }

func _load_state(state: Dictionary) -> void:
    position.x = state['x']
    position.y = state['y']
    team = state['t']
    previous_input = state['pi']
    health = state['hp']
    status = state['s']
    hitstop_duration = state['hs']
    current_hitstop_tick = state['hst']
    hitstun_duration = state['hsu']
    pushback = state['pb']
    velocity = state['v']
    attack_id = state['a']
    hit_by = bytes_to_var(state['hb'])

    var fsm_state = state['fs']
    var fsm_ticks_in_state = state['ft']
    fsm.load(fsm_state, fsm_ticks_in_state)

    if character != state['c']:
        push_error('''DESYNC: character in loaded state & memory do not match. 
        state:%s, mem: %s''' % [state['c'], character])

func _get_local_input() -> Dictionary:
    return input_retriever.retrieve_input()

func _predict_remote_input(old_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
    if ticks_since_real_input >= 5:
        return InputRetriever.EMPTY
    return old_input

func _network_process(input: Dictionary):
    if input.is_empty():
        input = InputRetriever.EMPTY
        
    # need to execute game logic here.
    # p1 and p2 apply inputs to state machine
    if current_hitstop_tick < hitstop_duration:
        current_hitstop_tick += 1
    else:
        fsm.process(input)
        position.x += velocity
    
    #fsm.process(input)
    #position.x += velocity

    # once both are complete, adjudicator resolves interactions
    #  calls methods on p1 and p2 as needed to apply results.
    player_processing_finished.emit()


func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
    # check required parameters are provided
    const essential_spawn_params = ['x', 'y', 'c', 't']
    var keys = data.keys()
    for essential_param in essential_spawn_params:
        assert(essential_param in keys, "ERROR: spawn method not called with essential input '%s'. 
            Input data:%s" % [essential_param, data])

    # look up hp value for character:
    data['hp'] = 100 # placeholder logic for now

    # overwrite other params with default values
    const spawn_num_ticks_in_state = 0
    const spawn_hitstop = 0
    const spawn_velocity = 0
    const initial_attack_id = 0
    data['pi'] = InputHelper.EMPTY
    data['s'] = Status.NEUTRAL
    data['fs'] = State.IDLE
    data['ft'] = spawn_num_ticks_in_state
    data['hs'] = spawn_hitstop
    data['hst'] = spawn_hitstop
    data['hsu'] = spawn_hitstop
    data['pb'] = spawn_velocity
    data['v'] = spawn_velocity
    data['a'] = initial_attack_id
    data['hb'] = var_to_bytes({})
    return data

func _network_spawn(data: Dictionary) -> void:
    # need to do first time setup (based on character selection, etc.)
    character = data['c']
    health = data['hp']
    team = data['t']
    fsm.prepare_states()
    # remaining setup is identical to any ordinary load state
    _load_state(data)

func _network_despawn() -> void:
    pass


###############
# PLAYER ENUM #
###############
enum Side {
    P1 = 0,
    P2 = 1
}

enum Characters {
    SPEED = 0,
    REACH = 1,
}

enum Status {
    NEUTRAL = 0,
    STARTUP = 1,
    ACTIVE = 2,
    RECOVERY = 3,
    HITSTUN = 4,
}

enum State {
    NONE = -1,
    IDLE = 0,
    WALK = 1,
    A = 2,
    B = 3,
    C = 4,
    SPECIAL_CANCEL = 5,
    SPECIAL_NEUTRAL = 6,
    BURST = 7,
    HITSTUN = 8,
}
