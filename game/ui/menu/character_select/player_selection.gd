class_name PlayerSelection extends Control

@onready var character_name_label: Label = $"%CharacterName"
@onready var character_sprite: Sprite2D = $"%CharacterSprite"

func preview_character(new_character_spec: CharacterSpec) -> void:
    print_debug("previewing character spec %s..." % new_character_spec.name)

func select_character(new_character_spec: CharacterSpec) -> void:
    print_debug("selected character spec %s!" % new_character_spec.name)
    character_name_label.text = new_character_spec.name
    character_sprite.texture = new_character_spec.animation_sprite
    
