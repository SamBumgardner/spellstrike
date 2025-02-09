# Finite State Machine
# Used by player class to handle transition between various states
class_name Fsm extends RefCounted

var state := Player.State.IDLE
var ticks_in_state := 0

func load(
	new_state: Player.State,
	new_ticks_in_state: int
) -> void:
	state = new_state
	ticks_in_state = new_ticks_in_state
	# execute logic to jump to this state
