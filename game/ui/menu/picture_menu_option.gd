class_name PictureMenuOption extends MenuOption

func set_texture(new_texture: Texture2D) -> void:
    $MarginContainer/TextureRect.texture = new_texture
