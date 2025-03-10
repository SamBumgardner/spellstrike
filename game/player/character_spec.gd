class_name CharacterSpec extends Resource

var name: String
var victory_portrait: Texture
var defeat_portrait: Texture

func _init() -> void:
    name = "placeholder_name"
    victory_portrait = load("res://assets/art/placeholder_victory_portrait.tres")
    defeat_portrait = load("res://assets/art/placeholder_defeat_portrait.tres")
