extends Node2D

@export var music : AudioStream
#@export var path : String

func _ready():
	add_to_group("stage")
	
	if music:
		AudioManager.playMusic(music, false, true)
	PlayerData.location = scene_file_path
	PlayerData.autoSave()
	randomize()
