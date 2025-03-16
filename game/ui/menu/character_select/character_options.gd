class_name CharacterOptions extends AbstractControllerMenu

signal character_selected(acting_side: Player.Side, character_spec: CharacterSpec)
signal character_selection_moved(acting_side: Player.Side, character_spec: CharacterSpec)
signal selection_canceled(acting_side: Player.Side)

@onready var targetable_ui: Array = $MC/GC.get_children()

var character_specifications: Array[CharacterSpec] = [
    load("res://assets/data/character/character_speed.tres"),
    load("res://assets/data/character/character_reach.tres"),
    load("res://assets/data/character/character_speed.tres"),
    load("res://assets/data/character/character_reach.tres"),
]

func get_initial_element(cursor_side: Player.Side) -> Control:
    var midpoint: int = (targetable_ui.size() - 1) / 2
    var remainder: int = (targetable_ui.size() - 1) % 2
    var extra = 0 if cursor_side == Player.Side.P1 else remainder
    
    return targetable_ui[midpoint + extra] as Control

func get_initial_character(cursor_side: Player.Side) -> CharacterSpec:
    var midpoint: int = (targetable_ui.size() - 1) / 2
    var remainder: int = (targetable_ui.size() - 1) % 2
    var extra = 0 if cursor_side == Player.Side.P1 else remainder
    
    return character_specifications[midpoint + extra]

func initialize_focus_neighbors() -> void:
    for i in targetable_ui.size():
        targetable_ui[i].focus_neighbor_left = targetable_ui[i - 1].get_path()
        targetable_ui[i].focus_neighbor_right = targetable_ui[(i + 1) % targetable_ui.size()].get_path()

func generate_actions_map() -> Dictionary:
    var result = {}
    for i in targetable_ui.size():
        var key = "%s.%s" % [targetable_ui[i].name, 'a']
        result[key] = character_selected.emit.bind(character_specifications[i]) #TODO: include character number and cursor owner.
        key = "%s.%s" % [targetable_ui[i].name, 'b']
        result[key] = selection_canceled.emit.bind(character_specifications[i])
    
    return result

func generate_moved_map() -> Dictionary:
    var result = {}
    for i in targetable_ui.size():
        var key = targetable_ui[i].name
        result[key] = character_selection_moved.emit.bind(character_specifications[i])
    
    return result
