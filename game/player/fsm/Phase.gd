class_name Phase extends Resource

@export var duration := 0
@export var endless := false
@export var player_status := Player.Status.NEUTRAL
@export var hitboxes := []
@export var hurtboxes := []
@export var effects: Array[PhaseEffect] = []
