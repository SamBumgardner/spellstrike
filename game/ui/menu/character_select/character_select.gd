class_name CharacterSelect extends Control

@onready var character_options: CharacterOptions = $UI/CharacterOptions
@onready var cursor_logics: Array[CursorLogic] = [$UI/CharacterOptions/CursorLogic, $UI/CharacterOptions/CursorLogic2]
@onready var frame_cursors: Array[FrameCursor] = [$UI/CharacterOptions/FrameCursor, $UI/CharacterOptions/FrameCursor2]

func _ready() -> void:
    var match_options = MatchOptions.generate_default()
    
    for i in Player.Side.size():
        cursor_logics[i].selection_changed.connect(frame_cursors[i]._on_selection_changed)
        cursor_logics[i].status_changed.connect(frame_cursors[i]._on_status_changed)
        cursor_logics[i].initialize(character_options, match_options.input_retrievers[i], CursorLogic.Status.ACTIVE)

    if multiplayer.is_server():
        SyncManager.start()
