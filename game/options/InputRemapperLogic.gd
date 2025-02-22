class_name InputMapperLogic extends Node

signal waiting_for_next_input
signal input_received
signal remap_complete

var input_remapping: bool = false
var already_mapped: Array = []

func _input(event: InputEvent) -> void:
    if input_remapping:
        if not event.is_echo() and event.is_pressed():
            if event is InputEventJoypadButton:
                var input_info = [event.device, event.button_index]
                if not in_already_mapped(input_info):
                    input_received.emit(input_info)
            elif event is InputEventJoypadMotion and event.axis_value > .1:
                var input_info = [event.device, event.axis, event.axis_value]
                if not in_already_mapped(input_info.slice(0, 2)):
                    input_received.emit(input_info)
            elif event is InputEventKey:
                var input_info = [event.physical_keycode]
                if not in_already_mapped(input_info):
                    input_received.emit(input_info)

        get_viewport().set_input_as_handled()

func in_already_mapped(input_info: Array) -> bool:
    var result := input_info in already_mapped
    if not result:
        already_mapped.append(input_info)
    return result

func collect_input_mapping() -> Dictionary:
    var new_input_map = {}

    input_remapping = true
    already_mapped = []

    for input_key in InputRetriever.INPUT_KEYS:
        waiting_for_next_input.emit(input_key)
        print_debug("waiting for input ", input_key)

        var input_identifier: Array = await input_received

        new_input_map[input_key] = input_identifier

    input_remapping = false
    remap_complete.emit(new_input_map)
    print_debug("input remap complete")

    return new_input_map
