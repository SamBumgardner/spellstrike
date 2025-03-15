class_name CharacterSpec extends Resource

@export var name: String
@export var victory_portrait: Texture
@export var defeat_portrait: Texture

@export var animation_sprite: Texture
@export var special_icon: Texture

@export var walk_speed: int = 5
@export var back_walk_speed: int = 3
@export var walk_accel: int = 5
@export var walk_drag: int = 2
@export var width: int = 128
@export var pushbox_width: int = 64

@export var max_hp: int = 150
@export var special_uses: int = 5
@export var states: Array[FsmState]

func _init() -> void:
    name = "placeholder_name"
    victory_portrait = load("res://assets/art/placeholder_victory_portrait.tres")
    defeat_portrait = load("res://assets/art/placeholder_defeat_portrait.tres")
