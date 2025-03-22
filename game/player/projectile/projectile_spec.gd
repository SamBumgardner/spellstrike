class_name ProjectileSpec extends Resource

@export var animation_sprite: Texture
@export var sprite_hframes: int
@export var sprite_vframes: int
@export var states: Dictionary
@export var spawn_location_x: SpawnLocation

enum SpawnLocation {
    ON_REQUESTOR = 0,
    ON_ENEMY = 1,
}
