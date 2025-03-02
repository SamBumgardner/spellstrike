class_name ConditionLib

enum Condition {
    NONE = -1,
    HAS_ENOUGH_SPECIAL = 0,
}

static var methods := {
    Condition.HAS_ENOUGH_SPECIAL: has_enough_special
}

# CONDITION METHODS #
static func has_enough_special(owner: Player, _input: Dictionary, _ticks_in_state: int, minimum_inclusive: int) -> bool:
    return owner.special_uses >= minimum_inclusive
