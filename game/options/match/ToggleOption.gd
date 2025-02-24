class_name ToggleOption extends HBoxContainer

@export var text: String = "":
    set(x):
        $Label.text = x

@export var button_pressed: bool:
    get():
        return $CheckBox.button_pressed
    set(x):
        $CheckBox.button_pressed = x
