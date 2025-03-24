class_name PlayerSelection extends Control

@export var flip_character_sprite: bool = false

@onready var player_name_label: Label = $"%PlayerName"
@onready var character_name_label: Label = $"%CharacterName"
@onready var character_sprite: Sprite2D = $"%CharacterSprite"

func init(player_information: PlayerInformation) -> void:
    player_name_label.text = player_information.player_name

func _ready() -> void:
    character_sprite.flip_h = flip_character_sprite

func preview_character(new_character_spec: CharacterSpec) -> void:
    character_name_label.text = new_character_spec.name
    character_sprite.texture = new_character_spec.animation_sprite
    modulate_character_info(Color(Color.WHITE, .5))
    
func select_character(new_character_spec: CharacterSpec) -> void:
    character_name_label.text = new_character_spec.name
    character_sprite.texture = new_character_spec.animation_sprite
    modulate_character_info(Color.WHITE)
    
func modulate_character_info(new_modulate: Color) -> void:
    for canvas_item: CanvasItem in [character_name_label, character_sprite]:
        canvas_item.modulate = new_modulate
