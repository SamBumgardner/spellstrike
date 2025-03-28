class_name Projectile extends Player

signal expired(projectile: Projectile)
signal despawned

const DESPAWN_DELAY := 10

@onready var despawn_timer = $DespawnTimer

func _ready():
    despawn_timer.timeout.connect(_on_despawn_delay_timeout)
    add_to_group("network_sync")

func reset() -> void:
    pass

func perform_hit(_attack_data: AttackData) -> void:
    # state for projectile decides what to do if projectile hits.
    pass

func handle_defeat() -> void:
    pass

func receive_hit(_attack_data: AttackData, _attack_owner: Object) -> void:
    # become destroyed?
    # should probably switch states to a "getting destroyed state" instead that despawns at end.
    SyncManager.despawn(self)

##########################
# ROLLBACK IMPLEMENTATION #
##########################
func _save_state() -> Dictionary:
    return {
        'x': position.x,
        'y': position.y,
        't': team,
        'fs': fsm.state,
        'ft': fsm.ticks_in_state,
        'v': velocity,
        'fd': facing_direction,
        'sx': scale.x,
        'a': attack_id,
    }

func _load_state(state: Dictionary) -> void:
    position.x = state['x']
    position.y = state['y']
    team = state['t']
    velocity = state['v']
    facing_direction = state['fd']
    scale.x = state['sx']
    attack_id = state['a']

    var fsm_state = state['fs']
    var fsm_ticks_in_state = state['ft']
    fsm.load(fsm_state, fsm_ticks_in_state)

func _get_local_input() -> Dictionary:
    return {}

func _predict_remote_input(_old_input: Dictionary, _ticks_since_real_input: int) -> Dictionary:
    return {}

func _network_process(input: Dictionary):
    # need to execute game logic here.
    # p1 and p2 apply inputs to state machine
    animation.play()
    fsm.process(action_buffer)
    position.x += velocity
    
func _network_postprocess(_input: Dictionary):
    if status in [Status.STARTUP, Status.ACTIVE]:
        z_index = 1
    elif status in [Status.HITSTUN, Status.DEFEATED]:
        z_index = -1
    else:
        z_index = 0

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
    # check required parameters are provided
    const essential_spawn_params = ['x', 'y', 'projectile_spec', 't', 'fd', 'sx']
    var keys = data.keys()
    for essential_param in essential_spawn_params:
        assert(essential_param in keys, "ERROR: spawn method not called with essential input '%s'. 
            Input data:%s" % [essential_param, data])

    var projectile_spec: ProjectileSpec = data['projectile_spec']
    fsm.prepare_states(projectile_spec.states)
    sprite.texture = projectile_spec.animation_sprite
    sprite.hframes = projectile_spec.sprite_hframes
    sprite.vframes = projectile_spec.sprite_vframes
    data.erase('projectile_spec')

    opponent = data['opponent']
    data.erase('opponent')

    # placeholder logic, should be pulled from projectile type or provided by creator.
    const spawn_velocity = 0

    # overwrite other params with default values
    const spawn_num_ticks_in_state = 0
    const initial_attack_id = 0
    data['fs'] = State.IDLE
    data['ft'] = spawn_num_ticks_in_state
    data['v'] = spawn_velocity
    data['a'] = initial_attack_id
    return data

func _network_spawn(data: Dictionary) -> void:
    show()
    # basic setup is identical to any ordinary load state
    _load_state(data)
    # Run initial state transition in
    fsm.reset()

func expire() -> void:
    expired.emit(self)
    hide()
    despawn_timer.start(DESPAWN_DELAY)

func _on_despawn_delay_timeout():
    despawned.emit()
    SyncManager.despawn(self)

# ENUM #

enum ProjectileType {
    DELAYED_BLAST_FIREBALL = 0,
    EARTH_SPIKE = 1,
}
