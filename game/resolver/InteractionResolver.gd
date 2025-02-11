class_name InteractionResolver extends RefCounted

var p1: Player
var p2: Player

var num_players_complete := 0

# need to wait for p1 and p2 to communicate that they're done.
# When both are finished, evaluates ways players interacted.
# For each interaction, call method(s) on both players to cause appropriate reactions

func _setup_players(new_p1: Player, new_p2: Player) -> void:
    p1 = new_p1
    p2 = new_p2
    p1.player_processing_finished.connect(_on_player_processing_complete)
    p2.player_processing_finished.connect(_on_player_processing_complete)

func _on_player_processing_complete() -> void:
    num_players_complete += 1
    
    if num_players_complete == 2:
        # Get list of results
        _adjudicate_interactions(p1, p2)
        
        # Apply result to each object, let them do their thing
        
        # Reset for next tick
        num_players_complete = 0

func _adjudicate_interactions(player1: Player, player2: Player) -> void:
    # goal:
    #  For each game object, determine what "result" it ultimately had this frame.
    #  These results can be mututally exclusive with one another, so we want one "outcome" remembered per object.
    
    # attacks hit:
    # For each player, check if their hitbox pool has a collision.
    #  remember it for now - if they didn't get hit, then we want to apply appropriate hitstop based on their move.
    
    # For each player, check if their hurtbox pool got hit.
    #  This will replace the "successful hit" status for them
    # for each successful collision, apply damage to the other player.
    player1.active_hurtbox_hit(0, AttackData.new())
    pass

func _has_successful_attack(attacker: Player) -> bool:
    return attacker.active_hitbox_hit()

enum ResultType {
    NEUTRAL = 0,
    HIT_OTHER = 1,
    GOT_HIT = 2,
    GOT_COUNTER_HIT = 3,
}

class AdjudicationResult:
    var result: ResultType = ResultType.NEUTRAL
    var hurt_by_details # need to do some kind of tracking to make sure a character doesn't get double-hit by a single action.
    var natural_pushback
