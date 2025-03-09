class_name RoundsTracker extends PanelContainer

@export var wins_manager: WinsManager
@export var tracking_side: Player.Side

@onready var empty_slots_container = $Panel/EmptySlots
@onready var round_win_container = $Panel/RoundWinIcons
@onready var empty_slot = $Panel/EmptySlots/EmptySlot
@onready var win_icon = $Panel/RoundWinIcons/WinIcon

var slots: Array
var win_icons: Array

var max_rounds: int
var rounds_won: int

func initialize_rounds(starting_won: int = 0, starting_max_rounds = 1) -> void:
    rounds_won = starting_won
    max_rounds = starting_max_rounds

    slots = [empty_slot]
    win_icons = [win_icon]

    assert(empty_slots_container.get_child_count() == 1 and round_win_container.get_child_count() == 1,
        "Should not call `initialize_rounds` more than once per RoundsTracker object.")
    for i in max_rounds - 1:
        var new_slot = empty_slot.duplicate()
        empty_slots_container.add_child(new_slot)
        slots.append(new_slot)
        var new_win_icon = win_icon.duplicate()
        round_win_container.add_child(new_win_icon)
        win_icons.append(new_win_icon)

    _update_visible_round_wins()

func _process(_delta: float) -> void:
    if wins_manager._rounds_won[tracking_side] != rounds_won:
        rounds_won = wins_manager._rounds_won[tracking_side]
        _update_visible_round_wins()

func _update_visible_round_wins() -> void:
    for i in win_icons.size():
        if i < rounds_won:
            win_icons[i].show()
        else:
            win_icons[i].hide()
