extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"

func init_room():
	MetSys.get_current_room_instance().adjust_camera_limits(player.get_node("Camera2D"))


func _init():
	var playerScene = load("res://Overworld/playerOverworld.tscn")
	player = playerScene.instantiate()

func _ready():
	MetSys.reset_state()
	
	add_child(player)
	default_room_setup()


func default_room_setup():
	# search for spawn point so we can run scenes from editor
	var spawn_point := get_tree().root.find_child("spawnPoint", true, false)
	if spawn_point:
		print("Moving player to spawn")
		player.global_position = spawn_point.global_position
