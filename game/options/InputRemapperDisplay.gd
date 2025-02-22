class_name InputRemapperDisplay extends Control

@export var highlight_color = Color(Color.GREEN, .5)

@onready var action_input_pairs: Array = get_tree().get_nodes_in_group("action_input_pair")
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/Confirm
@onready var redo_button: Button = $VBoxContainer/HBoxContainer/Redo

@onready var confirmed: Signal = confirm_button.pressed
@onready var redo: Signal = redo_button.pressed

var action_input_pairs_mapped: Dictionary
var selected_action_input_pair: ActionInputPair

func _ready() -> void:
    action_input_pairs_mapped = {}
    assert(InputRetriever.INPUT_FRIENDLY_NAMES.size() == action_input_pairs.size())
    for i in action_input_pairs.size():
        action_input_pairs_mapped[InputRetriever.INPUT_KEYS[i]] = action_input_pairs[i]
    
func start(side: Player.Side = Player.Side.P1) -> void:
    visible = true
    $VBoxContainer/Title.text = "Remap Input: P%d" % (side + 1)

    # clear out old mapping info:
    assert(InputRetriever.INPUT_FRIENDLY_NAMES.size() == action_input_pairs.size())
    for i in action_input_pairs.size():
        action_input_pairs[i].set_mapping(InputRetriever.INPUT_FRIENDLY_NAMES[i], "")

    confirm_button.disabled = true
    redo_button.disabled = true

    grab_focus.call_deferred()

func _on_waiting_for_next_input(input_key: String) -> void:
    # get the action_input_pairs
    if selected_action_input_pair != null:
        selected_action_input_pair.unhighlight()

    selected_action_input_pair = action_input_pairs_mapped[input_key]
    selected_action_input_pair.highlight(highlight_color)

func _on_input_received(input_info: Array) -> void:
    selected_action_input_pair.input = str(input_info.slice(0, 2))

func _on_remap_complete(_complete_input_map) -> void:
    selected_action_input_pair.unhighlight()
    confirm_button.disabled = false
    redo_button.disabled = false
    confirm_button.grab_focus.call_deferred()
