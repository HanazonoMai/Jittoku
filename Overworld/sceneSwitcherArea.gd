extends Area2D

var target: String
var spawnPoint: String = ""

var player_scene = preload("res://Overworld/playerOverworld.tscn")

func _on_body_entered(_body) -> void:
	if not (_body is PlayerOverworld):
		return
	PlayerData.player_spawn_handled_by_scene_switcher = true
	var packedScene = load(target)
	var newScene = packedScene.instantiate()

	
	call_deferred("swapScene", newScene)
	
func swapScene(newScene):
	SceneTransition.exit()
	await get_tree().create_timer(1).timeout
	get_tree().root.add_child(newScene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = newScene
	newScene.set_y_sort_enabled(true)
	var _spawnPoint
	
	if spawnPoint == "":
		_spawnPoint = newScene.get_node("spawnPoint")
	else:
		newScene.spawnPointUsed = spawnPoint
		_spawnPoint = newScene.get_node("spawnPoints/" + spawnPoint)
		
	#var player = player_scene.instantiate()
	#newScene.add_child(player)
	#player.transfer_global_position(_spawnPoint.global_position)
	
	SceneTransition.enter()
