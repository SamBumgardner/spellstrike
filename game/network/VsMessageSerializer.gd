extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

func serialize_input(input: Dictionary) -> PackedByteArray:
	return var_to_bytes(InputHelper.to_int(input))

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	return InputHelper.to_dict(bytes_to_var(serialized))
