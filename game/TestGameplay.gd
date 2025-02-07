extends Node2D

func _ready():
	SyncManager.sync_started.connect(_on_sync_started)
	SyncManager.start()

func _on_sync_started():
	SyncManager.spawn("fighter", self, preload("res://player/Player.tscn"));
