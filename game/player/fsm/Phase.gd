class_name Phase extends Resource

@export var starting_tick := 0
@export var player_status := Player.Status.NEUTRAL
@export var hitboxes := []
@export var hurtboxes := []
@export var effects: Array[PhaseEffect] = []