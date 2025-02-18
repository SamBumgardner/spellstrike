class_name HealthTracker extends HBoxContainer

@onready var display_label: Label = $Label2

@export var display_health: int:
    set(x):
        display_health = x
        if display_label != null:
            display_label.text = str(display_health)

@export var actual_health: int:
    set(x):
        actual_health = x
        display_health = actual_health

@export var tracked_player: Player

func _process(_delta: float):
    if tracked_player != null and tracked_player.health != actual_health:
        actual_health = tracked_player.health
