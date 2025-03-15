extends Control

var primary_corner: Corner
var target_ui_element: Control
var frame_color: Color

func _draw():
    if target_ui_element != null:
        if primary_corner != CORNER_TOP_LEFT:
            scale = Vector2(-1, 1)
            position = Vector2(target_ui_element.size.x, 0)
        
        set_size(target_ui_element.size * Vector2(.5, 1))
        draw_rect(Rect2(Vector2.ZERO, target_ui_element.size), frame_color, false, FrameCursor.border_width)
