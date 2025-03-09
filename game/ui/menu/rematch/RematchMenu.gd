extends PanelContainer

@onready var rematch_button = $"%RematchOption"
@onready var quit_button = $"%QuitOption"

@onready var ui_targets: Array = [rematch_button, quit_button]

@onready var rematch_pressed: Signal = rematch_button.pressed
@onready var quit_pressed: Signal = quit_button.pressed

var input_retriever: InputRetriever = InputRetriever.new()
var hovered_ui_target: Control = null

func init_input_mapping(new_input_mapping: Dictionary):
    input_retriever.input_ids = new_input_mapping

func _ready() -> void:
    add_to_group("network_sync")
    hovered_ui_target = rematch_button
