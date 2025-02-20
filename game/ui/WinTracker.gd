class_name WinTracker extends HBoxContainer

@onready var display_label: Label = $Label2

var wins: int = 0

func _ready() -> void:
    add_to_group("network_sync")
    visible = false

func increment_wins() -> int:
    wins += 1
    display_label.text = str(wins)
    visible = true
    return wins

func _save_state() -> Dictionary:
    return {
        'v': visible,
        'w': wins
    }

func _load_state(state: Dictionary) -> void:
    visible = state['v']
    wins = state['w']
    
