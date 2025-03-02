class_name SpecialCounter extends PanelContainer

@onready var special_display: Label = $"%SpecialCount"

@export var num_specials: int:
    set(x):
        num_specials = x
        special_display.text = str(num_specials)

@export var tracked_player: Player:
    set(x):
        tracked_player = x
        reset_special_count()

func reset_special_count() -> void:
    num_specials = tracked_player.special_uses

func update_special_count(new_count: int) -> void:
    if new_count < num_specials:
        print_debug("Can trigger visual effects for specials changing here")
    elif new_count > num_specials:
        push_warning("number of specials increased, probably because of rollback")
    
    num_specials = new_count

func _process(_delta: float) -> void:
    if tracked_player != null and tracked_player.special_uses != num_specials:
        update_special_count(tracked_player.special_uses)
