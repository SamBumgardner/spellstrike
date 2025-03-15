class_name FrameCursor extends Control

const border_width = 2

@export var primary_corner: Corner = CORNER_TOP_LEFT
@export var frame_color: Color = Color.RED
@export var nametag: String:
    set(x):
        nametag = x
        if is_inside_tree():
            update_nametag_label()
@export var target_ui_element: Control:
    set(x):
        target_ui_element = x
        if is_inside_tree():
            update_target_element()

@onready var nametag_label: Label = $Nametag
@onready var foreground_half: Control = $ForegroundHalf

func _ready() -> void:
    update_target_element()
    update_nametag_label()
    foreground_half.frame_color = frame_color
    foreground_half.primary_corner = primary_corner
    if primary_corner == CORNER_TOP_LEFT:
        nametag_label.set_anchors_preset(PRESET_TOP_LEFT)
        nametag_label.position = Vector2.ZERO

func _draw():
    if target_ui_element != null:
        if primary_corner != CORNER_TOP_LEFT:
            draw_set_transform(Vector2(target_ui_element.size.x, 0), 0, Vector2(-1, 1))
            
        draw_rect(Rect2(Vector2.ZERO, target_ui_element.size), frame_color, false, border_width)
        
        if nametag != null and not nametag == "":
            draw_rect(Rect2(Vector2.ZERO, nametag_label.size), frame_color)

func update_target_element():
    foreground_half.target_ui_element = target_ui_element
    if target_ui_element == null:
        hide()
    else:
        reparent.call_deferred(target_ui_element, false)
        

func update_nametag_label():
    nametag_label.text = nametag
    if nametag != null and not nametag.is_empty():
        nametag_label.show()
    queue_redraw()
