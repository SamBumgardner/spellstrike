extends Control

var primary_corner: Corner
var target_ui_element: Control
var frame_color: Color

func _draw():
    if target_ui_element != null:
        if primary_corner != CORNER_TOP_LEFT:
            draw_set_transform(Vector2(target_ui_element.size.x, 0), 0, Vector2(-1, 1))
        
        draw_line(Vector2.ZERO, target_ui_element.size * Vector2(.5, 0), frame_color, FrameCursor.border_width)
        draw_line(Vector2.ZERO - Vector2(0, FrameCursor.border_width / 2), target_ui_element.size * Vector2(0, 1) + Vector2(0, FrameCursor.border_width / 2), frame_color, FrameCursor.border_width)
        draw_line(target_ui_element.size * Vector2(0, 1), target_ui_element.size * Vector2(.5, 1), frame_color, FrameCursor.border_width)
