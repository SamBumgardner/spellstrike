class_name MenuOption extends Control

const border_width: float = 4
enum OptionState {
    NORMAL = 0,
    HOVERED = 1,
    SELECTED = 2,
}

@export var state: OptionState = OptionState.NORMAL:
    set(x):
        state = x
        queue_redraw()
@export var hovered_color: Color = Color.SKY_BLUE
@export var selected_color: Color = Color.WHITE

func _draw():
    match state:
        OptionState.NORMAL:
            pass
        OptionState.HOVERED:
            draw_rect(Rect2(Vector2.ZERO, size), Color(hovered_color, .3), true)
            draw_rect(Rect2(Vector2.ZERO, size), hovered_color, false, border_width)
        OptionState.SELECTED:
            draw_rect(Rect2(Vector2.ZERO, size), Color(selected_color, .3), true)
