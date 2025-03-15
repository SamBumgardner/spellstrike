class_name CharacterSelect extends Control

@onready var character_options: CharacterOptions = $UI/CharacterOptions

func _ready() -> void:
    $FrameCursor.target_ui_element = character_options.targetable_ui[0]
    $FrameCursor2.target_ui_element = character_options.targetable_ui[1]
