class_name WinsManager extends RefCounted

signal round_won(side: Player.Side)
signal round_tied()

signal game_won(side: Player.Side)
signal play_next_round(new_round_number: int)

var _rounds_won: Array[int]
var _games_won: Array[int]

func _init(initial_games_won: Array[int] = [], initial_rounds_won: Array[int] = []):
    _games_won = _initialize_tracking_array() if initial_games_won.is_empty() else initial_games_won
    _rounds_won = _initialize_tracking_array() if initial_rounds_won.is_empty() else initial_rounds_won

func _initialize_tracking_array() -> Array[int]:
    var result: Array[int] = []
    result.resize(Player.Side.size())
    result.fill(0)
    return result

func round_completed(winning_player: Player, defeated_players: Array):
    if winning_player != null:
        _rounds_won[winning_player.team] += 1
        var losing_sides: Array = defeated_players.map(func(x): return x.team)
        round_won.emit(winning_player.team, losing_sides)
    else:
        round_tied.emit()

func check_game_finished():
    var winners = []
    var total_round_count: int = 0
    for i in _rounds_won.size():
        total_round_count += _rounds_won[i]
        if _rounds_won[i] >= MatchOptions.default_rounds_to_win:
            winners.append(i)
    
    if winners.size() == 1:
        game_won.emit(winners[0])
    elif winners.size() == 0:
        play_next_round.emit(total_round_count + 1)
    else: # somehow multiple players won???
        push_error("ERROR: had multiple winners after round completed")
        game_won.emit(winners[0])
