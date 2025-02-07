class_name Player extends Node2D

var input_retriever: InputRetriever
var sam_previous_input: Dictionary

func _init():
	input_retriever = InputRetriever.new()

func _ready():
	add_to_group("network_sync")

func _save_state() -> Dictionary:
	return {}

func _load_state() -> void:
	pass

func _get_local_input() -> Dictionary:
	return input_retriever.retrieve_input()

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	if ticks_since_real_input >= 5:
		return {}
	return previous_input

func _network_process(input: Dictionary):
	if input["l"]:
		print_debug("moving left")
		pass 
	
	# need to execute game logic here.
	# p1 and p2 apply inputs to state machine
	# once both are complete, adjudicator resolves interactions
	#  calls methods on p1 and p2 as needed to apply results.

func _network_spawn(data: Dictionary) -> void:
	sam_previous_input = InputRetriever.empty_input()

func _network_despawn() -> void:
	pass
