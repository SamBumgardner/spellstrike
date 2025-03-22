class_name ConditionLib

enum Condition {
    NONE = -1,
    HAS_ENOUGH_SPECIAL = 0,
    INPUT_HELD = 1,
}

static var methods := {
    Condition.HAS_ENOUGH_SPECIAL: has_enough_special,
    Condition.INPUT_HELD: input_held,
}

# CONDITION METHODS #
static func has_enough_special(owner: Player, _input_buffer: ActionBuffer, _ticks_in_state: int, minimum_inclusive: int) -> bool:
    return owner.special_uses >= minimum_inclusive

static func input_held(owner: Player, input_buffer: ActionBuffer, _ticks_in_state: int, required_held: Array, adapt_to_facing: bool = true) -> bool:
    var condition_met: bool = true

    for input_key in required_held:
        if input_key in ['l', 'r'] and adapt_to_facing and owner.facing_direction == Player.Side.P2:
            match input_key:
                'l': input_key = 'r'
                'r': input_key = 'l'
        
        condition_met = input_buffer.is_pressed(input_key)
        if not condition_met:
            break
    
    return condition_met
