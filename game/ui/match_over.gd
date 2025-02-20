extends Control

func _save_state() -> Dictionary:
    return {
        'v': visible
    }

func _load_state(state: Dictionary) -> void:
    visible = state['v']
