class_name Player extends Node2D

signal request_projectile(projectile_type: Projectile.ProjectileType, requestor: Player)
signal player_processing_finished
signal defeated

# State Dictionary:
    # x
    # y
    # t - team (Side enum)
    # c - character (int, corresponds to enum)
    # hp - remaining health (int)
    # s - status (int, corresponds to enum)
    # fs - fsm state
    # ft - number of ticks spent in current fsm state
    # hs - total hitstop duration (usually 0)
    # hst - current hitstop tick
    # cs - counterhit starter
    # rcc - received combo count
    # hsu - hitstun duration
    # pb - pushback
    # pbf - pushback from (other player, etc.)
    # v - velocity
    # fd - facing direction
    # sx - scale x (for actual facing)
    # a - attack id
    # ah - attack hit
    # hb - hit by
    # su - special uses available
    # ap - active projetiles
    # 

@onready var hurtbox_pool: Area2D = $HurtboxPool
@onready var hurtboxes := hurtbox_pool.get_children()
@onready var hitbox_pool: Area2D = $HitboxPool
@onready var hitboxes := hitbox_pool.get_children()
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: NetworkAnimationPlayer = $Animation
@onready var pushbox: CollisionShape2D = $Pushbox

# composed utils
var input_retriever: InputRetriever
var fsm: Fsm
@onready var action_buffer: ActionBuffer = $ActionBuffer

# TODO: move these to character spec
var max_health: int
var walk_speed: int = 5
var back_walk_speed: int = 3
var walk_accel: int = 5
var walk_drag: int = 2
var width: int = 128

var opponent: Player
var maximum_projectiles: int

# Custom state variables
var team: Side
var health: int
var velocity: int
var facing_direction: Side

var status: Status

var hitstop_duration: int
var current_hitstop_tick: int
var counterhit_starter: bool
var received_combo_count: int

var hitstun_duration: int
var pushback: int
var pushback_from: String

var attack_id: int
var attack_hit: bool
var hit_by: Dictionary

var special_uses: int

var active_projectiles: int

# Stateless variables: refresh every frame
var current_attack_data: AttackData
var initial_spawn_state: Dictionary
var pushback_velocity: int = 0

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
        attack_hit = false

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

func reset() -> void:
    _load_state(initial_spawn_state)
    fsm.force_change_state(State.IDLE)

func initialize_character_data(new_character_spec: CharacterSpec) -> void:
    walk_speed = new_character_spec.walk_speed
    back_walk_speed = new_character_spec.walk_speed
    walk_accel = new_character_spec.walk_accel
    walk_drag = new_character_spec.walk_drag
    width = new_character_spec.width

    max_health = new_character_spec.max_hp
    health = new_character_spec.max_hp
    special_uses = new_character_spec.special_uses

    maximum_projectiles = new_character_spec.maximum_active_projectiles

    fsm.prepare_states(new_character_spec.states)

    sprite.texture = new_character_spec.animation_sprite
    
    
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
                collided = overlapped(hitbox, hurtbox) # TODO: replace with actual collision resolution method
                if collided:
                    break ;
            if collided:
                break ;
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

static func get_overlap_x_distance(a: CollisionShape2D, b: CollisionShape2D) -> int:
    var overlap_distance := 0
    var start1 = a.global_position.x - a.shape.size.x / 2
    var length1 = a.shape.size.x
    var start2 = b.global_position.x - b.shape.size.x / 2
    var length2 = b.shape.size.x

    if start1 == start2:
        overlap_distance = min(length1, length2)
    elif start1 < start2:
        overlap_distance = max(0, start1 + length1 - start2)
    elif start2 < start1:
        overlap_distance = max(0, start2 + length2 - start1)
    
    return overlap_distance

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
    attack_hit = true
    hitstop_duration = attack_data.hitstop
    current_hitstop_tick = 0

func receive_hit(attack_data: AttackData, attack_owner: Object) -> void:
    # do whatever steps are neeed to apply attack data (damage received, add hitstop, change state)
    # add attacker id to map of things you've been hit by, value is attack's numeric id.
    var counterhit: bool = status in [Status.STARTUP, Status.ACTIVE]
    if received_combo_count == 0:
        counterhit_starter = counterhit
    const counterhit_damage_bonus: float = 1.5
    const counterhit_bonus_hitstun: int = 2

    hitstun_duration = attack_data.hitstun + (counterhit_bonus_hitstun if counterhit else 0)
    hitstop_duration = attack_data.hitstop
    current_hitstop_tick = 0
    pushback = scale_incoming_pushback(attack_data.pushback)
    pushback_from = attack_owner.name
    health -= int(scale_incoming_damage(attack_data.damage) * (counterhit_damage_bonus if counterhit else 1.0))
    received_combo_count += attack_data.num_hits
    SyncManager.play_sound("%s_%s" % [name, attack_owner.attack_id], attack_data.sound_effect)
    
    if health > 0:
        # force player to jump to hurt state.
        fsm.force_change_state(State.HITSTUN)
    elif status not in [Status.DEFEATED, Status.VICTORY]:
        handle_defeat()

func scale_incoming_damage(unscaled_damage: int) -> int:
    return max(unscaled_damage - received_combo_count * 2, 2)

func scale_incoming_pushback(unscaled_pushback: int) -> int:
    return unscaled_pushback + max(0, (received_combo_count - 3) * 2)

func handle_defeat() -> void:
    # stop all control
    # play defeat animation
    receive_defeat()
    defeated.emit()
    
func receive_victory() -> void:
    #TODO: have some logic here to do timeout win instead of normal win.
    fsm.force_change_state(State.VICTORY)

func receive_defeat() -> void:
    #TODO: add logic here to do timeout loss instead of normal loss.
    fsm.force_change_state(State.DEFEATED)

func get_health_percent() -> int:
    return (100 * health) / max_health

##########################
# ROLLBACK IMPLEMNTATION #
##########################
func _save_state() -> Dictionary:
    return {
        'x': position.x,
        'y': position.y,
        't': team,
        'hp': health,
        's': status,
        'fs': fsm.state,
        'ft': fsm.ticks_in_state,
        'hs': hitstop_duration,
        'hst': current_hitstop_tick,
        'rcc': received_combo_count,
        'hsu': hitstun_duration,
        'pb': pushback,
        'pbf': pushback_from,
        'v': velocity,
        'fd': facing_direction,
        'sx': scale.x,
        'a': attack_id,
        'ah': attack_hit,
        'hb': var_to_bytes(hit_by),
        'su': special_uses,
        'ap': active_projectiles
    }

func _load_state(state: Dictionary) -> void:
    position.x = state['x']
    position.y = state['y']
    team = state['t']
    health = state['hp']
    status = state['s']
    hitstop_duration = state['hs']
    current_hitstop_tick = state['hst']
    received_combo_count = state['rcc']
    hitstun_duration = state['hsu']
    pushback = state['pb']
    pushback_from = state['pbf']
    velocity = state['v']
    facing_direction = state['fd']
    scale.x = state['sx']
    attack_id = state['a']
    attack_hit = state['ah']
    hit_by = bytes_to_var(state['hb'])
    special_uses = state['su']
    active_projectiles = state['ap']

    var fsm_state = state['fs']
    var fsm_ticks_in_state = state['ft']
    fsm.load(fsm_state, fsm_ticks_in_state)

func _get_local_input() -> Dictionary:
    return input_retriever.retrieve_input()

func _predict_remote_input(old_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
    if ticks_since_real_input >= 5:
        return InputRetriever.EMPTY
    return old_input

func _network_process(input: Dictionary):
    if input.is_empty():
        input = InputRetriever.EMPTY

    # add data to input buffer.
    action_buffer.push_frame(input)

    # pushblock should be reset to 0 and recalc'd every tick. This prevents movement during hitstop.
    pushback_velocity = 0

    # need to execute game logic here.
    # p1 and p2 apply inputs to state machine
    if current_hitstop_tick < hitstop_duration:
        animation.pause()
        current_hitstop_tick += 1
    else:
        animation.play()
        action_buffer.set_lookback_distance(fsm.states[fsm.state].button_buffer_lookback)
        fsm.process(action_buffer)
        position.x += velocity
    
    if status != Player.Status.HITSTUN and status != Player.Status.DEFEATED:
        received_combo_count = 0
        counterhit_starter = false

func _network_postprocess(_input: Dictionary):
    if status in [Status.STARTUP, Status.ACTIVE, Status.VICTORY]:
        z_index = 1
    elif status in [Status.HITSTUN, Status.DEFEATED]:
        z_index = -1
    else:
        z_index = 0
    

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
    # check required parameters are provided
    const essential_spawn_params = ['x', 'y', 'character_spec', 't']
    var keys = data.keys()
    for essential_param in essential_spawn_params:
        assert(essential_param in keys, "ERROR: spawn method not called with essential input '%s'. 
            Input data:%s" % [essential_param, data])

    initialize_character_data(data['character_spec'])
    data['hp'] = health
    data['su'] = special_uses
    data.erase('character_spec')

    # overwrite other params with default values
    const spawn_num_ticks_in_state = 0
    const spawn_hitstop = 0
    const spawn_combo_size = 0
    const spawn_velocity = 0
    const initial_attack_id = 0
    const initial_active_projectiles = 0
    data['s'] = Status.NEUTRAL
    data['fs'] = State.IDLE
    data['ft'] = spawn_num_ticks_in_state
    data['hs'] = spawn_hitstop
    data['hst'] = spawn_hitstop
    data['rcc'] = spawn_combo_size
    data['hsu'] = spawn_hitstop
    data['pb'] = spawn_velocity
    data['pbf'] = ""
    data['v'] = spawn_velocity
    data['fd'] = Player.Side.P1 if sign(data['x']) < 0 else Player.Side.P2
    data['sx'] = get_side_scale(facing_direction)
    data['a'] = initial_attack_id
    data['ah'] = false
    data['hb'] = var_to_bytes({})
    data['ap'] = initial_active_projectiles
    return data

func _network_spawn(data: Dictionary) -> void:
    initial_spawn_state = data
    # need to do first time setup (based on character selection, etc.)
    team = data['t']

    # remaining setup is identical to any ordinary load state
    _load_state(data)

#func _network_despawn() -> void:
    #pass

###############
# PLAYER ENUM #
###############
enum Side {
    P1 = 0,
    P2 = 1
}

static func get_side_scale(side: Side) -> int:
    return 1 if side == Side.P1 else -1

enum Status {
    NEUTRAL = 0,
    STARTUP = 1,
    ACTIVE = 2,
    RECOVERY = 3,
    HITSTUN = 4,
    DEFEATED = 5,
    VICTORY = 6,
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
    DEFEATED = 9,
    VICTORY = 10,
    CHARACTER_0 = 11,
    CHARACTER_1 = 12,
    CHARACTER_2 = 13,
    CHARACTER_3 = 14,
}
