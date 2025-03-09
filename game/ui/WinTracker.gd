class_name WinTracker extends HBoxContainer

@export var wins_manager: WinsManager
@export var tracking_side: Player.Side

@onready var display_label: Label = $Label2

var wins: int = 0:
    set(x):
        if wins != x:
            wins = x
            display_label.text = str(wins)
            visible = wins > 0

func _ready() -> void:
    visible = false

func _process(_delta: float) -> void:
    wins  = wins_manager.get_game_win_counts()[tracking_side]
