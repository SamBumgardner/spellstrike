class_name Player extends Node2D

# State Dictionary:
	# x
	# y
	# pi - previous input (int, bitwise flags)
	# c - character (int, corresponds to enum)
	# hp - remaining health (int)
	# s - status (int, corresponds to enum)
	# fs - fsm state
	# ft - number of ticks spent in current fsm state
	# hs - total hitstop duration (usually 0)
	# hst - current hitstop tick
	# 

const input_dict_keys = ['l', 'r', 'a', 'b', 'c', 's']

# composed utils
var input_retriever: InputRetriever
var fsm: Fsm

# Custom state variables
var character: Characters
var health: int

var previous_input: int
var status: Status

var hitstop_duration: int
var current_hitstop_tick: int

func _init():
	input_retriever = InputRetriever.new()
	fsm = Fsm.new()

func _ready():
	add_to_group("network_sync")
 
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
		's': status,
		'fs': fsm.state,
		'ft': fsm.ticks_in_state,
		'hs': hitstop_duration,
		'hst': current_hitstop_tick
	}

func _load_state(state: Dictionary) -> void:
	global_position.x = state['x']
	global_position.y = state['y']
	previous_input = state['pi']
	health = state['hp']
	status = state['s']
	hitstop_duration = state['hs']
	current_hitstop_tick = state['hst']

	var fsm_state = state['fs']
	var fsm_ticks_in_state = state['ft']
	fsm.load(fsm_state, fsm_ticks_in_state)

	if character != state['c']:
		push_error('''DESYNC: character in loaded state & memory do not match. 
		state:%s, mem: %s''' % [state['c'], character])

func _get_local_input() -> Dictionary:
	return input_retriever.retrieve_input()

func _predict_remote_input(old_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	if ticks_since_real_input >= 5:
		return InputRetriever.EMPTY
	return old_input

func _network_process(input: Dictionary):
	assert(not input.is_empty())

	var movement_direction: int = 0
	if input["l"]:
		movement_direction -= 1
	if input["r"]:
		movement_direction += 1
	if input["a"]:
		print_debug("peer %s says node %s had 'a' pressed" % [multiplayer.get_unique_id(), get_path()])
		print_debug("is multiplayer authority? %s" % (get_multiplayer_authority() == multiplayer.get_unique_id()))
	
	const MOVE_SPEED = 10
	position.x += MOVE_SPEED * movement_direction
	# need to execute game logic here.
	# p1 and p2 apply inputs to state machine
	fsm.process(input)
	# once both are complete, adjudicator resolves interactions
	#  calls methods on p1 and p2 as needed to apply results.


func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	# check required parameters are provided
	const essential_spawn_params = ['x', 'y', 'c']
	var keys = data.keys()
	for essential_param in essential_spawn_params:
		if essential_param not in keys:
			push_error("ERROR: spawn method not called with essential input '%s'. 
				Input data:%s" % [essential_param, data])

	# look up hp value for character:
	data['hp'] = 100 # placeholder logic for now

	# overwrite other params with default values
	const spawn_num_ticks_in_state = 0
	const spawn_hitstop = 0
	data['pi'] = InputHelper.EMPTY
	data['s'] = Status.NEUTRAL
	data['fs'] = State.IDLE
	data['ft'] = spawn_num_ticks_in_state
	data['hs'] = spawn_hitstop
	data['hst'] = spawn_hitstop
	return data

func _network_spawn(data: Dictionary) -> void:
	# need to do first time setup (based on character selection, etc.)
	character = data['c']
	health = data['hp']
	fsm.prepare_states()
	# remaining setup is identical to any ordinary load state
	_load_state(data)

func _network_despawn() -> void:
	pass


enum Characters {
	SPEED = 0,
	REACH = 1,
}

enum Status {
	NEUTRAL = 0,
	STARTUP = 1,
	ACTIVE = 2,
	RECOVERY = 3,
	HITSTOP = 4,
}

enum State {
	NONE = -1,
    IDLE = 0,
    WALK = 1,
    A = 2,
    B = 3,
    C = 4,
    SPECIAL_CANCEL = 5,
    SPECIAL_NEUTRAL = 6,
    BURST = 7,
}
