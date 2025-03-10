class_name ResultsBox extends Control

@onready var portrait = $PanelContainer/HBoxContainer/CharacterPortrait

func set_results(winner: bool, player_information: PlayerInformation) -> void:
    if winner:
        portrait.texture = player_information.character_spec.victory_portrait
    else:
        portrait.texture = player_information.character_spec.defeat_portrait
