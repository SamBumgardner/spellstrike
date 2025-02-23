class_name HealthTracker extends Control

@export var follow_delay_duration: float = .5
@export var follow_rate_change: float = 10
@export var health_stability_threshold: int = 5

@onready var display_label: Label = $TextDisplay/Label2
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_follow: ProgressBar = $HealthBar/HealthFollow
@onready var delay_follow_timer: Timer = $DelayFollow

var is_following: bool = false
var actual_health_stable: int = 0

@export var display_health: int:
    set(x):
        display_health = x
        if display_label != null:
            display_label.text = str(display_health)
        if health_bar != null:
            health_bar.value = display_health
            if display_health > health_follow.value:
                health_follow.value = display_health
            else:
                delay_follow_timer.stop()
                delay_follow_timer.start(follow_delay_duration)

@export var actual_health: int:
    set(x):
        if actual_health != x:
            actual_health = x
            actual_health_stable = 0
            is_following = false

@export var tracked_player: Player:
    set(x):
        tracked_player = x
        actual_health = tracked_player.health
        health_bar.value = tracked_player.health
        health_follow.value = tracked_player.health

func _ready():
    delay_follow_timer.timeout.connect(_on_delay_follow_timeout)

func _physics_process(_delta: float) -> void:
    if actual_health_stable > health_stability_threshold and display_health != actual_health:
        display_health = actual_health
    else:
        actual_health_stable += 1

func _process(delta: float):
    if tracked_player != null and tracked_player.health != actual_health:
        actual_health = tracked_player.health
    
    if is_following and health_follow.value > health_bar.value:
        var difference = health_follow.value - health_bar.value
        var intended_change = max(delta * follow_rate_change, difference * 2 * delta)
        if intended_change > (difference):
            health_follow.value = health_bar.value
            is_following = false
        else:
            health_follow.value -= intended_change
        

func _on_delay_follow_timeout() -> void:
    is_following = true
