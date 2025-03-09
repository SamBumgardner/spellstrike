class_name RoundsTracker extends PanelContainer

@export var tracking_side: Player.Side

@onready var empty_slots_container = $Panel/EmptySlots
@onready var round_win_container = $Panel/RoundWinIcons

var max_rounds: int
var rounds_won: int = 0

func _init(starting_won: int = 0, starting_max_rounds = 0) -> void:
    rounds_won = starting_won
    max_rounds = starting_max_rounds

func _ready() -> void:
    # use max_rounds to decide how many copies of the texture rect should be created in both containers 
    pass
