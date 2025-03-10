class_name ComboCounter extends Control

const counter_color: Color = Color.RED
const normal_color: Color = Color.WHITE

@onready var hits_container: Control = $"%HitsContainer"
@onready var hits_counter: Label = $"%HitsCounter"
@onready var counterhit_indicator: Label = $"%CounterhitIndicator"

@export var number_hits: int:
    set(x):
        number_hits = x
        if number_hits > 1:
            hits_counter.text = str(number_hits)
            hits_container.show()
        else:
            hits_container.hide()

@export var counterhit_starter: bool:
    set(x):
        counterhit_starter = x
        if counterhit_starter:
            counterhit_indicator.show()
            modulate = counter_color
        else:
            counterhit_indicator.hide()
            modulate = normal_color

@export var tracked_player: Player:
    set(x):
        tracked_player = x
        number_hits = tracked_player.received_combo_count

func _physics_process(_delta: float) -> void:
    if tracked_player != null:
        if number_hits != tracked_player.received_combo_count:
            number_hits = tracked_player.received_combo_count
        if counterhit_starter != tracked_player.counterhit_starter:
            counterhit_starter = tracked_player.counterhit_starter
