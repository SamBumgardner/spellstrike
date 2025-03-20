@tool
extends Node2D

const default_char_width = 128
const default_char_height = 128
const default_char_rect = Rect2(Vector2(-1 * default_char_width / 2, -1 * default_char_height / 2), Vector2(default_char_width, default_char_height))
const default_char_origin_vector = Vector2(-1 * default_char_width / 2, -1 * default_char_height / 2)
const default_char_color = Color.GRAY

const hitbox_color = Color.RED
const hurtbox_color = Color.GREEN

const outline_width := 1
const inner_alpha := .1

@export var displayed_phase: int
@export var viewed_state: FsmState

func _draw() -> void:
    draw_rect(default_char_rect, default_char_color, false, 1)
    draw_rect(default_char_rect, Color(default_char_color, .1))

    if viewed_state != null and displayed_phase < viewed_state.phases.size():
        _draw_shape_group(viewed_state.phases[displayed_phase].hurtboxes, hurtbox_color)
        _draw_shape_group(viewed_state.phases[displayed_phase].hitboxes, hitbox_color)

func _draw_shape_group(shapes: Array[RectangleSpec], draw_color: Color):
    for shape in shapes:
        draw_set_transform(Vector2(shape.x_offset, shape.y_offset))
        var rectangle = Rect2((-1 * Vector2(shape.width, shape.height) / 2), Vector2(shape.width, shape.height))
        #print(rectangle)
        draw_rect(rectangle, Color(draw_color, .1))
        draw_rect(rectangle, Color(draw_color), false, 1)

func _process(_delta: float) -> void:
    queue_redraw()
