# Finite State Machine
# Used by player class to handle transition between various states
class_name Fsm extends RefCounted

var states: Array[FsmState]
var owner: Player
var state := Player.State.IDLE
var ticks_in_state := 0

static var player_states := {
    Player.State.IDLE: preload("res://assets/data/states/character/speed/IdleState.tres"),
    Player.State.WALK: preload("res://assets/data/states/character/speed/WalkState.tres"),
    Player.State.A: preload("res://assets/data/states/character/speed/LightAttackState.tres"),
    Player.State.B: preload("res://assets/data/states/character/speed/MediumAttackState.tres"),
    Player.State.C: preload("res://assets/data/states/character/speed/HeavyAttackState.tres"),
    Player.State.SPECIAL_CANCEL: preload("res://assets/data/states/character/speed/DelayedFireballCast.tres"),
    Player.State.SPECIAL_NEUTRAL: preload("res://assets/data/states/character/speed/DefensiveSpecialState.tres"),
    Player.State.HITSTUN: preload("res://assets/data/states/character/speed/HurtState.tres"),
    Player.State.DEFEATED: preload("res://assets/data/states/character/speed/DefeatedState.tres"),
    Player.State.VICTORY: preload("res://assets/data/states/character/speed/VictoryState.tres"),
    Player.State.CHARACTER_0: preload("res://assets/data/states/character/speed/LightAttackChainState.tres"),
}

static var projectile_states := [
    preload("res://assets/data/states/projectile/delay_fireball/DelayFireballPriming.tres"),
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    preload("res://assets/data/states/projectile/delay_fireball/DelayFireballExplosion.tres"),
    preload("res://assets/data/states/projectile/ExpiredState.tres")
]

func prepare_states(provided_states: Array[FsmState]) -> void:
    # need to take character spec as an input, then populate the `states` dict with their state objects
    states = provided_states

func reset() -> void:
    state = Player.State.IDLE
    ticks_in_state = 0
    states[state].transition_in(owner, owner.action_buffer)

func load(
    new_state: Player.State,
    new_ticks_in_state: int
) -> void:
    state = new_state
    ticks_in_state = new_ticks_in_state

func process(action_buffer: ActionBuffer) -> void:
    # Feed input into current state's process, loop through state transitions to get to ending state.
    var next_state = states[state].process(owner, action_buffer, ticks_in_state)

    var total_transitions := 0
    const too_many_transitions = 50
    while next_state != Player.State.NONE:
        # Check for infinite loop
        total_transitions += 1
        if total_transitions >= too_many_transitions:
            push_error("ERROR: Too many state transitions in one tick. Check for loops!")
            break
            
        # Prepare to transition
        states[state].transition_out(owner, action_buffer, ticks_in_state)
        state = next_state
        ticks_in_state = 0

        # Transition to next state
        states[state].transition_in(owner, action_buffer)
        next_state = states[state].process(owner, action_buffer, ticks_in_state)
        
    ticks_in_state += 1

func force_change_state(next_state: Player.State) -> void:
    states[state].transition_out(owner, owner.action_buffer, ticks_in_state)
    state = next_state
    ticks_in_state = 0
    # Transition to next state
    states[state].transition_in(owner, owner.action_buffer)
