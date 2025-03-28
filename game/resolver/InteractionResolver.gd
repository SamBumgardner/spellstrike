class_name InteractionResolver extends Node

signal frame_resolved

const min_x = -1 * TestGameplay.STAGE_WIDTH
const max_x = TestGameplay.STAGE_WIDTH

var p1: Player
var p2: Player
var camera_control: CameraControl

var num_actors_complete := 0
var active_actors := 0

var registered_actors: Array = []


func _ready() -> void:
    add_to_group("network_sync")
# need to wait for p1 and p2 to communicate that they're done.
# When both are finished, evaluates ways players interacted.
# For each interaction, call method(s) on both players to cause appropriate reactions

func _setup_players(new_p1: Player, new_p2: Player) -> void:
    p1 = new_p1
    p2 = new_p2
    registered_actors.append(p1)
    registered_actors.append(p2)
    active_actors += 2

func register_new_projectile(new_projectile: Projectile) -> void:
    if new_projectile not in registered_actors:
        registered_actors.append(new_projectile)

func _network_postprocess(_input: Dictionary) -> void:
        _resolve_player_movement()
        # Get list of results
        _adjudicate_interactions(registered_actors)

func _resolve_player_movement() -> void:
    var players = [p1, p2]

    # separate players if pushboxes overlap
    var overlap_distance = Player.get_overlap_x_distance(p1.pushbox, p2.pushbox)
    if overlap_distance > 0:
        # whoever has the higher magnitude of distance gets the extra bit of push
        var separate_distance = min(overlap_distance / 2, MatchOptions.separate_distance)
        var remainder = overlap_distance % 2
        players.sort_custom(func(a, b): return abs(a.position.x) > abs(b.position.x))
        players[0].position.x += (separate_distance + remainder) * sign(players[0].position.x)
        players[1].position.x += separate_distance * -1 * sign(players[0].position.x)

    # if a player is past edge and has pushback also in that direction, apply pushback to their attacker.
    for player in players:
        var predicted_x = player.position.x + player.pushback_velocity
        var player_attackers = players.filter(func(x): return x.name == player.pushback_from)
        if not player_attackers.is_empty() and player_attackers[0] is not Projectile and (\
                (predicted_x <= min_x + player.width / 2 and player.pushback_velocity < 0) \
                or (predicted_x >= max_x - player.width / 2 and player.pushback_velocity > 0)):
            _apply_reversed_pushback(player, player_attackers[0])
    
    for player in players:
        # Apply pushback now that calculations are done
        player.position.x += player.pushback_velocity
        # Clamp player x values to stay within camera boundaries
        _restrict_player_x(player)

    # update player's side information based on position. It's up to player when to fix their scale.
    if p1.position.x < p2.position.x:
        p1.facing_direction = 0
        p2.facing_direction = 1
    else:
        p1.facing_direction = 1
        p2.facing_direction = 0
    # Camera position will be set in CameraControl's post-process
    
    for player in players:
        if player.status == Player.Status.NEUTRAL:
            player.scale.x = Player.get_side_scale(player.facing_direction)
        
    
func _restrict_player_x(player: Player):
    player.position.x = camera_control.clamp_to_logical_camera(player.position.x, player.width)

func _apply_reversed_pushback(pushed_player: Player, attacker: Player) -> void:
    if attacker.pushback_velocity != 0:
        attacker.pushback_velocity = attacker.pushback_velocity
    else:
        attacker.pushback_velocity = -1 * pushed_player.pushback_velocity


func _adjudicate_interactions(actors: Array) -> void:
    # goal:
    #  For each game object, determine what "result" it ultimately had this frame.
    #  These results can be mututally exclusive with one another, so we want one "outcome" remembered per object.
    # attacks hit:
    # For each player, check if their hitbox pool has a collision.
    #  remember it for now - if they didn't get hit, then we want to apply appropriate hitstop based on their move.
    # For each player, check if their hurtbox pool got hit.
    #  This will replace the "successful hit" status for them
    # for each successful collision, apply damage to the other player.
    # get all hitboxes, sort by allegiance.
    var p1_attack_shapes: Array = []
    var p2_attack_shapes: Array = []
    for actor in actors:
        var allied_attack_shapes: Array
        match actor.team:
            Player.Side.P1:
                allied_attack_shapes = p1_attack_shapes
            Player.Side.P2:
                allied_attack_shapes = p2_attack_shapes
        var attack_shape: Array = actor.get_hitboxes()
        if not attack_shape.is_empty():
            allied_attack_shapes.append(attack_shape)
    
    # store 'true' for each actor path if they had an attack that succeeded.
    var attacker_hit := []
    var defender_hit_by_dict := {}
    for actor in actors:
        var attack_shapes = p1_attack_shapes if actor.team == Player.Side.P2 else p2_attack_shapes
        var attacks_hit: Array = actor.active_hurtbox_hit(attack_shapes)
        var overlapping_areas: Array = []
        for i in attacks_hit.size():
            if attacks_hit[i]:
                overlapping_areas.append(attack_shapes[i])
        
        var actually_hit_by: Array = []
        for area in overlapping_areas:
            # determine if they've already been hit by this attack
            var attacker = area[0].owner
            var attacker_path = attacker.get_path()
            if not (actor.hit_by as Dictionary).has(attacker_path) or actor.hit_by[attacker_path] < attacker.attack_id:
                # this is a legitimate attack
                actor.hit_by[attacker_path] = attacker.attack_id
                actually_hit_by.append([attacker.current_attack_data, attacker])
                attacker_hit.append(attacker)
        
        if not actually_hit_by.is_empty():
            defender_hit_by_dict[actor] = actually_hit_by
    # Check if attacker_hit_dict has keys that aren't in some "hit by" dictionary. 
    
    var hit_defenders = defender_hit_by_dict.keys()
    for attacker in attacker_hit:
        if attacker not in hit_defenders:
            attacker.perform_hit(attacker.current_attack_data)
    
    for defender in hit_defenders:
        var hit_attacks = defender_hit_by_dict[defender]
        var total_hit: Array
        if hit_attacks.size() > 1:
            total_hit = hit_attacks.reduce(AttackData.combine_overlapping_attacks, [AttackData.new(), null])
        else:
            total_hit = hit_attacks[0]
        defender.receive_hit(total_hit[0], total_hit[1])
        

func _has_successful_attack(attacker: Player) -> bool:
    return attacker.active_hitbox_hit()

func decide_timeout_results() -> TimeoutResult:
    var result = TimeoutResult.new()
    if p1.get_health_percent() > p2.get_health_percent():
        result.winning_player = p1
        result.losing_player = p2
    elif p1.get_health_percent() < p2.get_health_percent():
        result.winning_player = p2
        result.losing_player = p1
    else:
        result.tie_players = [p1, p2]
    
    return result

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

class TimeoutResult:
    var winning_player: Player
    var losing_player: Player
    var tie_players: Array
