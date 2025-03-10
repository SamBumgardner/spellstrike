class_name SceneSwitchUtil

static var main_menu_scene: PackedScene = load("res://network/main.tscn")

static func change_scene(tree: SceneTree, new_root: Node) -> void:
    var old_root = tree.current_scene
    tree.root.add_child(new_root)
    tree.current_scene = new_root
    
    new_root.get_viewport().canvas_transform = Transform2D.IDENTITY
    old_root.queue_free()
