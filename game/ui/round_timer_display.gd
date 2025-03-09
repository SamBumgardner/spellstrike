class_name RoundTimerDisplay extends Control

@onready var seconds_remaining_label: Label = $SecondsRemaining

@export var tracked_timer: NetworkTimer:
    set(new_timer):
        tracked_timer = new_timer
        update_seconds_remaining_display()

var seconds_remaining: int = 0
        
func update_seconds_remaining_display() -> void:
    if tracked_timer != null and not tracked_timer.is_stopped():
        var actual_seconds_remaining: int = ticks_to_seconds(tracked_timer.ticks_left)
        if seconds_remaining != actual_seconds_remaining:
            seconds_remaining = actual_seconds_remaining
            seconds_remaining_label.text = str(seconds_remaining)

func ticks_to_seconds(ticks: int) -> int:
    return ceili(ticks / float(MatchOptions.ticks_per_second))
        
func _process(_delta: float) -> void:
    update_seconds_remaining_display()
