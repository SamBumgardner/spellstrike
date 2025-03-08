class_name FsmState extends Resource

@export var stateId := Player.State.IDLE
@export var expirationStateId := Player.State.IDLE
@export var phases: Array[Phase] = []
@export var transition_in_effects: Array[PhaseEffect] = []
@export var transition_out_effects: Array[PhaseEffect] = []
@export var animation_key: String = ""
@export var button_buffer_lookback: int = 8
@export var consumes_button_buffer: bool = true

func transition_in(owner: Player, input_buffer: ActionBuffer) -> void:
    # default behavior - change facing when entering a new state.
    EffectLib.match_scale_to_facing(owner, input_buffer, 0)
    owner.attack_hit = false
    
    # apply all one-time phase effects to do when transitioning into the state.
    const ticks_in_state = 0
    var params = [owner, input_buffer, ticks_in_state]
    _execute_effects(params, transition_in_effects)
    
    if owner.animation.current_animation != animation_key and not animation_key.is_empty():
        owner.animation.play(animation_key)
    else:
        owner.animation.seek(0)
    owner.animation.advance(0)
    
    owner.status = phases[0].player_status

func transition_out(owner: Player, input_buffer: ActionBuffer, ticks_in_state: int) -> void:
    # apply al one-time phase effects to do when transitioning out of this state.
    var params = [owner, input_buffer, ticks_in_state]
    _execute_effects(params, transition_out_effects)

# Override this in child classes. Should consider input to decide how states
#  may transition into each other. Returns the next state to transition to, or NONE to keep this 
#  active
func process(owner: Player, input_buffer: ActionBuffer, ticks_in_state: int) -> Player.State:
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
        const idle_actions := {
            "a": Player.State.A,
            "b": Player.State.B,
            "c": Player.State.C,
        }
        var next_state = EffectLib.start_action(owner, input_buffer, ticks_in_state, idle_actions, false)
        if next_state != Player.State.NONE:
            return next_state
    
    # Apply all phase effects
    var default_params = [owner, input_buffer, ticks_in_state]
    for effect in current_phase.effects:
        if (not effect.once_at_start or phase_just_started) and _check_effect_conditions(default_params, effect.conditions):
                var params = default_params.duplicate()
                params.append_array(effect.params)
                var next_state = (EffectLib.methods[effect.typeId] as Callable).callv(params)

                if next_state != Player.State.NONE:
                    return next_state
    
    # If we got here, no change to player's state.
    # Set collision according to current phase
    owner.set_hitboxes(current_phase.hitboxes, current_phase.attack_data, current_phase.new_attack and phase_just_started)
    owner.set_hurtboxes(current_phase.hurtboxes)
    return Player.State.NONE

# HELPER #
static func _check_effect_conditions(base_params: Array, conditions: Array[EffectCondition]) -> bool:
    var passed_conditions: bool = true
    for condition in conditions:
        var condition_params = base_params.duplicate()
        condition_params.append_array(condition.params)
        passed_conditions = (ConditionLib.methods[condition.conditionId] as Callable).callv(condition_params)

        if not passed_conditions:
            break
    
    return passed_conditions

static func _execute_effects(base_params, effects: Array[PhaseEffect]) -> void:
    for effect in effects:
        var params = base_params.duplicate()
        if _check_effect_conditions(params, effect.conditions):
            params.append_array(effect.params)
            (EffectLib.methods[effect.typeId] as Callable).callv(params)
