class_name MatchOptionsMenu extends Control

signal closed

func _ready() -> void:
    $"%DoneButton".pressed.connect(_on_done)

func open():
    show()
    $PanelContainer/VBoxContainer/InputOptions/VBoxContainer/HBoxContainer/P1_CPU/CheckBox.grab_focus()

func _on_done():
    hide()
    closed.emit()

func get_match_options() -> MatchOptions:
    return MatchOptions.new(
        get_input_retrievers()
    )

func get_input_retrievers() -> Array:
    var p1_cpu = SimpleCpuRetriever.new() if $"%CpuTypesP1".selected == 0 else RandomCpuInputRetriever.new()
    var p1_mapper = p1_cpu if $"%P1_CPU".button_pressed else InputRetriever.new(InputMappingManager.p1_input_mapping)
    
    var p2_cpu = SimpleCpuRetriever.new() if $"%CpuTypesP2".selected == 0 else RandomCpuInputRetriever.new()
    var p2_mapper = p2_cpu if $"%P2_CPU".button_pressed else InputRetriever.new(InputMappingManager.p2_input_mapping)
        
    return [p1_mapper, p2_mapper]
