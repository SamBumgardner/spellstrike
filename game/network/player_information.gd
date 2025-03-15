class_name PlayerInformation extends RefCounted

var network_id: int
var player_side: Player.Side
var input_retriever: InputRetriever
var character_spec: CharacterSpec
var number_of_wins: int

func _init(
    _network_id,
    _player_side,
    _input_retriever,
    _character_spec = null,
    _number_of_wins = 0
) -> void:
    network_id = _network_id
    player_side = _player_side
    input_retriever = _input_retriever
    character_spec = _character_spec
    number_of_wins = _number_of_wins
