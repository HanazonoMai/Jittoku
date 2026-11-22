extends Node2D

@export var music : AudioStream
#@export var path : String
var playerScene = preload("res://Overworld/playerOverworld.tscn")

var spawnPointUsed := "" ## which point we entered the room from

func _ready():
	var canvasModulate = get_node_or_null("CanvasModulate")
	if canvasModulate:
		canvasModulate.show()
	
	add_to_group("stage")
	if not has_node("playerOverworld") and PlayerData.player_spawn_handled_by_scene_switcher == false:
		var player = playerScene.instantiate()
		add_child(player)
		player.transfer_global_position($spawnPoint.global_position)
	if music:
		AudioManager.playMusic(music, false, true)
	PlayerData.location = scene_file_path
	PlayerData.autoSave()
	randomize()
