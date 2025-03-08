class_name Notification extends Control

const ERROR_TITLE: String = "%s ERROR"

@onready var notification_confirmed: Signal = $MC/VB/Confirm.pressed

@onready var title: Label = $MC/VB/Title
@onready var message: Label = $MC/VB/PC/MC/Message

func notify_error(error_type: String, new_message: String) -> Signal:
    title.text = ERROR_TITLE % error_type
    message.text = new_message

    show()
    return notification_confirmed

func _on_confirmed() -> void:
    hide()
