extends Node2D

@export var music : AudioStream
#@export var path : String

func _ready():
	add_to_group("stage")
	if not has_node("playerOverworld"):
		var playerScene = load("res://Overworld/playerOverworld.tscn")
		var player = playerScene.instantiate()
		add_child(player)
	if music:
		AudioManager.playMusic(music, false, true)
	PlayerData.location = scene_file_path
	PlayerData.autoSave()
	randomize()
