class_name CameraControl extends Node2D

@export var subjects: Array[Node2D]
const camera_width := 800
const min_global_x: int = -1 * TestGameplay.STAGE_WIDTH + camera_width / 2
const max_global_x: int = TestGameplay.STAGE_WIDTH - camera_width / 2

var viewport: Viewport

# state variable
var camera_midpoint: Vector2i = Vector2i.ZERO

func _ready():
    add_to_group("network_sync")
    viewport = get_viewport()

func _sync_start_initialize(new_subjects: Array[Node2D]) -> void:
    subjects = new_subjects
    _update_camera_position()

func _network_postprocess(_input: Dictionary) -> void:
    _update_camera_position()

func _update_camera_position() -> void:
    # for nodes in the array, find the average x value. 
    var avg_x = subjects.reduce(func(total, subject): return total + subject.global_position.x, 0) / subjects.size()
    camera_midpoint = Vector2i(clamp(avg_x, min_global_x, max_global_x), 0)

    # set that as camera transform
    viewport.canvas_transform = Transform2D.IDENTITY.translated(Vector2(camera_midpoint.x * -1 + camera_width / 2, 0))

func clamp_to_logical_camera(x: int, width: int) -> int:
    var min_x = (camera_midpoint.x - (camera_width / 2)) + width / 2
    var max_x = (camera_midpoint.x + (camera_width / 2)) - width / 2
    return clampi(x, min_x, max_x)

func _save_state() -> Dictionary:
    return {
        'cm': camera_midpoint
    }

func _load_state(state: Dictionary) -> void:
    camera_midpoint = state['cm']
