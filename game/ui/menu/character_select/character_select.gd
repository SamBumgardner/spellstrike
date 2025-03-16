class_name CharacterSelect extends Control

@onready var character_options: CharacterOptions = $UI/CharacterOptions
@onready var cursor_logics: Array[CursorLogic] = [$UI/CharacterOptions/CursorLogic, $UI/CharacterOptions/CursorLogic2]
@onready var frame_cursors: Array[FrameCursor] = [$UI/CharacterOptions/FrameCursor, $UI/CharacterOptions/FrameCursor2]
@onready var player_selections: Array[PlayerSelection] = [$UI/PlayerSelections/PlayerSelection, $UI/PlayerSelections/PlayerSelection2]

func _ready() -> void:
    var match_options = MatchOptions.generate_default()
    
    for i in Player.Side.values():
        cursor_logics[i].selection_changed.connect(frame_cursors[i]._on_selection_changed)
        cursor_logics[i].status_changed.connect(frame_cursors[i]._on_status_changed)
        cursor_logics[i].initialize(character_options, match_options.input_retrievers[i], CursorLogic.Status.ACTIVE, i)
    
    character_options.character_selected.connect(_on_character_selected)
    character_options.selection_canceled.connect(_on_selection_cancelled)

    if multiplayer.is_server():
        SyncManager.start()

func _on_character_selected(selecting_side: Player.Side, character_spec: CharacterSpec) -> void:
    cursor_logics[selecting_side].cursor_status = CursorLogic.Status.SELECTED
    player_selections[selecting_side].select_character(character_spec)
    
func _on_selection_cancelled(acting_side: Player.Side, character_spec: CharacterSpec) -> void:
    if cursor_logics[acting_side].cursor_status == CursorLogic.Status.SELECTED:
        cursor_logics[acting_side].cursor_status = CursorLogic.Status.ACTIVE
        player_selections[acting_side].preview_character(character_spec)
