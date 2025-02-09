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
        Player.State.IDLE: FsmState.new()
    }

func load(
    new_state: Player.State,
    new_ticks_in_state: int
) -> void:
    state = new_state
    ticks_in_state = new_ticks_in_state

func process(input: Dictionary) -> void:
    # Feed input into current state's process, loop through state transitions to get to ending state.
    var next_state = states[state].process(input, ticks_in_state)

    var total_transitions := 0
    const too_many_transitions = 50
    while next_state != Player.State.NONE:
        # Check for infinite loop
        total_transitions += 1
        if total_transitions >= too_many_transitions:
            push_error("ERROR: Too many state transitions in one tick. Check for loops!")
            
        # Prepare to transition
        states[state].transition_out()
        state = next_state
        ticks_in_state = 0

        # Transition to next state
        states[state].transition_in()
        states[state].process(input, ticks_in_state)
    
    ticks_in_state += 1
