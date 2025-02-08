# Finite State Machine
# Used by player class to handle transition between various states
class_name Fsm extends RefCounted

var action: Player.Action = Player.Action.NONE
var state: Player.State = Player.State.NEUTRAL
var ticks_in_state: int = 0

func load(
    new_state: Player.State,
    new_action: Player.Action,
    new_ticks_in_state: int
) -> void:
    state = new_state
    action = new_action
    ticks_in_state = new_ticks_in_state
    # execute logic to jump to this state
