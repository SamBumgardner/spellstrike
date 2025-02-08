class_name Player extends Node2D

# State Dictionary:
	# x
	# y
	# pi - previous input (int, bitwise flags)
	# c - character (int, corresponds to enum)
	# hp - remaining health (int)
	# s - current_state (int, corresponds to enum)
	# a - action (int, corresponds to enum)
	# t - ticks spent in current state
	# hs - total hitstop duration (usually 0)

const input_dict_keys = ['l', 'r', 'a', 'b', 'c', 's']

# composed utils
var input_retriever: InputRetriever
var fsm: Fsm

# Custom state variables
var character: Characters 
var health: int
var previous_input: int 
var hitstop_duration: int

func _init():
	input_retriever = InputRetriever.new()
	fsm = Fsm.new()

func _ready():
	add_to_group("network_sync")
 
func _fsm_load(
	fsm_state: State, 
	action: Action, 
	ticks_in_state: int,
	total_hitstop_duration: int
) -> void:
	hitstop_duration = total_hitstop_duration
	fsm.load(fsm_state, action, ticks_in_state)

##########################
# ROLLBACK IMPLEMNTATION #
##########################
func _save_state() -> Dictionary:
	return {
		'x': global_position.x,
		'y': global_position.y,
		'pi': previous_input,
		'c': character,
		'hp': health,
		's': fsm.state,
		'a': fsm.action,
		't': fsm.ticks_in_state,
		'hs': hitstop_duration,
	}

func _load_state(state: Dictionary) -> void:
	global_position.x = state['x']
	global_position.y = state['y']
	previous_input = state['pi']
	health = state['hp']

	var current_state = state['s']
	var current_action = state['a']
	var ticks_in_state = state['t']
	var total_hitstop_duration = state['hs']
	_fsm_load(current_state, current_action, ticks_in_state, total_hitstop_duration)

	if character != state['c']:
		push_error('''DESYNC: character in loaded state & memory do not match. 
		state: %s, mem: %s''' % [state['c'], character])

func _get_local_input() -> Dictionary:
	return input_retriever.retrieve_input()

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	if ticks_since_real_input >= 5:
		return {}
	return previous_input

func _network_process(input: Dictionary):
	var movement_direction: int = 0
	if input["l"]:
		movement_direction -= 1
	if input["r"]:
		movement_direction += 1
	
	const MOVE_SPEED = 10
	position.x += MOVE_SPEED * movement_direction
	# need to execute game logic here.
	# p1 and p2 apply inputs to state machine
	# once both are complete, adjudicator resolves interactions
	#  calls methods on p1 and p2 as needed to apply results.


func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	# check required parameters are provided
	const essential_spawn_params = ['x', 'y', 'c']
	var keys = data.keys()
	for essential_param in essential_spawn_params:
		if essential_param not in keys:
			push_error("ERROR: spawn method not called with essential input '%s'. 
				Input data: %s" % [essential_param, data])

	# look up hp value for character:
	data['hp'] = 100 # placeholder logic for now

	# overwrite other params with default values
	const spawn_num_ticks_in_state = 0
	const spawn_hitstop = 0
	data['pi'] = InputHelper.EMPTY 
	data['s'] = State.NEUTRAL
	data['a'] = Action.NONE 
	data['t'] = spawn_num_ticks_in_state
	data['hs'] = spawn_hitstop
	return data

func _network_spawn(data: Dictionary) -> void:
	# need to do first time setup (based on character selection, etc.)
	character = data['c']
	health = data['hp']
	# remaining setup is identical to any ordinary load state
	_load_state(data)

func _network_despawn() -> void:
	pass


enum Characters {
	SPEED = 0,
	REACH = 1,
}

enum Action {
	NONE = 0,
	A = 1,
	B = 2,
	C = 3,
	SPECIAL_CANCEL = 4,
	SPECIAL_NEUTRAL = 5,
	BURST = 6,
}

enum State {
	NEUTRAL = 0,
	WALK = 1,
	STARTUP = 2,
	ACTIVE = 3,
	RECOVERY = 4,
	HITSTOP = 5,
}
