extends CollisionShape2D

@export var  draw_color: Color = Color.GREEN

func _draw():
    draw_rect(Rect2(Vector2.ZERO - shape.size / 2, shape.size), Color(draw_color, .1))
    draw_rect(Rect2(Vector2.ZERO - shape.size / 2, shape.size), Color(draw_color), false, 1)
