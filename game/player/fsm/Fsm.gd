# Finite State Machine
# Used by player class to handle transition between various states
class_name Fsm extends RefCounted

var states := {}
var owner: Player
var state := Player.State.IDLE
var ticks_in_state := 0

func prepare_states() -> void:
    # need to take character spec as an input, then populate the `states` dict with their state objects
    states = {
        Player.State.IDLE: preload("res://assets/data/states/IdleState.tres"),
        Player.State.WALK: preload("res://assets/data/states/WalkState.tres"),
        Player.State.A: preload("res://assets/data/states/LightAttackState.tres"),
        Player.State.B: preload("res://assets/data/states/MediumAttackState.tres"),
        Player.State.C: preload("res://assets/data/states/HeavyAttackState.tres"),
        Player.State.HITSTUN: preload("res://assets/data/states/HurtState.tres"),
        Player.State.DEFEATED: preload("res://assets/data/states/DefeatedState.tres"),
        Player.State.VICTORY: preload("res://assets/data/states/VictoryState.tres"),
        Player.State.CHARACTER_0: preload("res://assets/data/states/LightAttackChainState.tres"),
    }

func load(
    new_state: Player.State,
    new_ticks_in_state: int
) -> void:
    state = new_state
    ticks_in_state = new_ticks_in_state

func process(input: Dictionary) -> void:
    # Feed input into current state's process, loop through state transitions to get to ending state.
    var next_state = states[state].process(owner, input, ticks_in_state)

    var total_transitions := 0
    const too_many_transitions = 50
    while next_state != Player.State.NONE:
        # Check for infinite loop
        total_transitions += 1
        if total_transitions >= too_many_transitions:
            push_error("ERROR: Too many state transitions in one tick. Check for loops!")
            break
            
        # Prepare to transition
        states[state].transition_out()
        state = next_state
        ticks_in_state = 0

        # Transition to next state
        states[state].transition_in(owner, input)
        next_state = states[state].process(owner, input, ticks_in_state)
    
    ticks_in_state += 1

func force_change_state(next_state: Player.State) -> void:
    states[state].transition_out()
    state = next_state
    ticks_in_state = 0
    # Transition to next state
    states[state].transition_in(owner, InputRetriever.EMPTY)
