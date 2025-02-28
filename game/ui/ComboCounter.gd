class_name ComboCounter extends Control

@onready var hits_counter: Label = $"%HitsCounter"

@export var number_hits: int:
    set(x):
        number_hits = x
        if number_hits > 1:
            hits_counter.text = str(number_hits)
            show()
        else:
            hide()

@export var tracked_player: Player:
    set(x):
        tracked_player = x
        number_hits = tracked_player.received_combo_count

func _physics_process(_delta: float) -> void:
    if tracked_player != null and number_hits != tracked_player.received_combo_count:
        number_hits = tracked_player.received_combo_count
