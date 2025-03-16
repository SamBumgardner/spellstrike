class_name CharacterOptions extends AbstractControllerMenu

@onready var targetable_ui: Array = $MC/GC.get_children()

func get_initial_element() -> Control:
    return targetable_ui[1] as Control

func initialize_focus_neighbors() -> void:
    for i in targetable_ui.size():
        targetable_ui[i].focus_neighbor_left = targetable_ui[i - 1].get_path()
        targetable_ui[i].focus_neighbor_right = targetable_ui[(i + 1) % targetable_ui.size()].get_path()

func generate_actions_map() -> Dictionary:
    return {
        "%s.%s" % [targetable_ui[0].name, 'a']: print.bind("pressed a on option 0!")
    }
