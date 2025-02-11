class_name FsmState extends Resource

@export var stateId := Player.State.IDLE
@export var expirationStateId := Player.State.IDLE
@export var phases: Array[Phase] = []
@export var transition_in_effects: Array[PhaseEffect] = []
@export var transition_out_effects: Array[PhaseEffect] = []

func transition_in(owner: Player, input: Dictionary) -> void:
    # apply all one-time phase effects to do when transitioning into the state.
    for effect in transition_in_effects:
        const ticks_in_state = 0
        var params = [owner, input, ticks_in_state]
        params.append_array(effect.params)
        (EffectLib.methods[effect.typeId] as Callable).callv(params)

func transition_out() -> void:
    # apply al one-time phase effects to do when transitioning out of this state.
    pass

# Override this in child classes. Should consider input to decide how states
#  may transition into each other. Returns the next state to transition to, or NONE to keep this 
#  active
func process(owner: Player, input: Dictionary, ticks_in_state: int) -> Player.State:
    # Determine Current Phase & Expiration
    var current_phase: Phase
    var phase_just_started := false
    var sum_duration := 0
    for phase in phases:
        phase_just_started = sum_duration == ticks_in_state
        sum_duration += phase.duration
        if sum_duration > ticks_in_state or phase.endless:
            current_phase = phase
            break
    
    if current_phase == null:
        return expirationStateId
    
    # Common Status Behavior (Neutral)
    owner.status = current_phase.player_status
    if owner.status == Player.Status.NEUTRAL:
        var next_state = EffectLib.start_action(owner, input, ticks_in_state)
        if next_state != Player.State.NONE:
            return next_state
    
    # Apply all phase effects
    var default_params = [owner, input, ticks_in_state]
    for effect in current_phase.effects:
        if not effect.once_at_start or phase_just_started:
            var params = default_params
            params.append_array(effect.params)
            var next_state = (EffectLib.methods[effect.typeId] as Callable).callv(params)

            if next_state != Player.State.NONE:
                return next_state
    
    # If we got here, no change to player's state.
    # Set collision according to current phase
    owner.set_hitboxes(current_phase.hitboxes, current_phase.attack_data, current_phase.new_attack)
    owner.set_hurtboxes(current_phase.hurtboxes)
    return Player.State.NONE
