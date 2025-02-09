extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

var produce_input_path := ""
var receive_input_path := ""

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(5)
	
	buffer.put_u32(all_input['$'])
	if (produce_input_path in all_input.keys()):
		buffer.put_u8(InputHelper.to_int(all_input[produce_input_path]))
	else:
		buffer.put_u8(0)

	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)

	var all_input := {}
	all_input['$'] = buffer.get_u32()
	var player_input = buffer.get_u8()
	all_input[receive_input_path] = InputHelper.to_dict(player_input)
	
	return all_input
