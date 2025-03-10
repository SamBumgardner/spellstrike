extends MenuOption

@export var option_text: String = "placeholder"

func _ready() -> void:
    $MarginContainer/Label.text = option_text
