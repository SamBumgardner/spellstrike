class_name ActionInputPair extends Control

const default_color: Color = Color.TRANSPARENT

var action: String:
    set(x):
        action = x
        $HBoxContainer/ActionName.text = action + ":"
var input: String:
    set(x):
        input = x
        $HBoxContainer/MappedInput.text = input

func set_mapping(new_action: String, new_input: String) -> void:
    action = new_action
    input = new_input

func highlight(color:Color) -> void:
    $ColorRect.color = color

func unhighlight() -> void:
    $ColorRect.color = default_color
