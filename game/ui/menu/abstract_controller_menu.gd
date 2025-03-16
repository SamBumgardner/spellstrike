class_name AbstractControllerMenu extends Control

var moved_map: Dictionary
var actions_map: Dictionary

# To be implemented by child
func get_initial_element(_cursor_side: Player.Side) -> Control:
    return null

# To be implemented by child
func generate_actions_map() -> Dictionary:
    return {}

func generate_moved_map() -> Dictionary:
    return {}

# To be implemented by child
func initialize_focus_neighbors() -> void:
    pass
    
func _ready() -> void:
    actions_map = generate_actions_map()
    moved_map = generate_moved_map()
    initialize_focus_neighbors()

func move_selection(starting_ui_element: Control, action_buffer: ActionBuffer, cursor_side: Player.Side) -> Control:
    var current_ui_element: Control = starting_ui_element
    if action_buffer.consume_just_pressed('l'):
        current_ui_element = try_get_node(current_ui_element.focus_neighbor_left, current_ui_element)
    if action_buffer.consume_just_pressed('r'):
        current_ui_element = try_get_node(current_ui_element.focus_neighbor_right, current_ui_element)
    if action_buffer.consume_just_pressed('u'):
        current_ui_element = try_get_node(current_ui_element.focus_neighbor_top, current_ui_element)
    if action_buffer.consume_just_pressed('d'):
        current_ui_element = try_get_node(current_ui_element.focus_neighbor_bottom, current_ui_element)
    
    if starting_ui_element != current_ui_element:
        var moved = moved_map.get(current_ui_element.name)
        if moved != null:
            moved.call(cursor_side)
    
    return current_ui_element

func try_get_node(nodepath: NodePath, default: Control) -> Control:
    if not nodepath.is_empty():
        return get_node(nodepath)
    else:
        return default

func act_on_selection(starting_ui_element: Control, action_buffer: ActionBuffer, cursor_side: Player.Side) -> void:
    const action_inputs = ['a', 'b', 'c', 's']
    var ui_element_name = starting_ui_element.name
    for action in action_inputs:
        if action_buffer.consume_just_pressed(action):
            action = actions_map.get("%s.%s" % [ui_element_name, action])
            if action != null:
                action.call(cursor_side)
