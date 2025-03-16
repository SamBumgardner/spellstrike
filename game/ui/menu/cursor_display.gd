class_name CursorDisplay extends Control

@export var move_sound: AudioStream = load("res://assets/sound/ui_boop.wav")
@export var selected_sound: AudioStream = load("res://assets/sound/ui_blip.wav")
@export var cancel_sound: AudioStream = load("res://assets/sound/ui_cancel.wav")

var current_target_ui: Control
var displayed_target_ui: Control

var current_status: CursorLogic.Status
var displayed_status: CursorLogic.Status

func _on_selection_changed(new_target_ui: Control):
    current_target_ui = new_target_ui

func _on_status_changed(new_status: CursorLogic.Status):
    current_status = new_status

func _process(_delta: float) -> void:
    if displayed_target_ui != current_target_ui:
        _update_displayed_target(current_target_ui)

    if displayed_status != current_status:
        _update_displayed_status(current_status)

# to be augmented by child classes
func _update_displayed_target(new_target_ui: Control) -> void:
    if displayed_target_ui != null:
        SyncManager.play_sound("%s_move" % name, move_sound)
    displayed_target_ui = new_target_ui

# to be augmented by child classes
func _update_displayed_status(new_status: CursorLogic.Status) -> void:
    # this is pretty rough, but it's fine if complexity doesn't increase
    if displayed_status == CursorLogic.Status.ACTIVE and new_status == CursorLogic.Status.SELECTED:
        SyncManager.play_sound("%s_selected" % name, selected_sound)
    elif displayed_status == CursorLogic.Status.SELECTED and new_status == CursorLogic.Status.ACTIVE:
        SyncManager.play_sound("%s_cancel" % name, cancel_sound)

    displayed_status = new_status
