class_name FsmState extends Resource

@export var stateId := Player.State.IDLE
@export var phases: Array[Phase] = []
@export var transition_in_effects: Array[PhaseEffect] = []
@export var transition_out_effects: Array[PhaseEffect] = []

func transition_in() -> void:
    # apply all one-time phase effects to do when transitioning into the state.
    pass

func transition_out() -> void:
    # apply al one-time phase effects to do when transitioning out of this state.
    pass

# Override this in child classes. Should consider input to decide how states
#  may transition into each other. Returns the next state to transition to, or NONE to keep this 
#  active
func process(owner: Player, input: Dictionary, ticks_in_state: int) -> Player.State:
    if ticks_in_state % 60 == 0:
        print_debug("state %s is processing input %s on tick %d" % [stateId, input, ticks_in_state])
    
    var current_phase: Phase
    for phase in phases:
        if phase.starting_tick <= ticks_in_state:
            current_phase = phase
        else:
            break
    
    var default_params = [owner, input, ticks_in_state]
    for effect in current_phase.effects:
        var params = default_params
        params.append_array(effect.params)
        var next_state = (EffectLib.methods[effect.typeId] as Callable).callv(params)

        if next_state != Player.State.NONE:
            return next_state
    
    return Player.State.NONE
