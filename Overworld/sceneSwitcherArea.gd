extends Area2D

var target: String
var spawnPoint: String = ""

func _on_body_entered(_body: CharacterBody2D) -> void:
	var packedScene = load(target)
	var newScene = packedScene.instantiate()

	
	call_deferred("swapScene", newScene)
	
func swapScene(newScene):
	get_tree().root.add_child(newScene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = newScene
	var _spawnPoint
	
	if spawnPoint == "":
		_spawnPoint = newScene.get_node("spawnPoint")
	else:
		_spawnPoint = newScene.get_node("spawnPoints/" + spawnPoint)
	var player = newScene.get_node("playerOverworld")
	player.global_position = _spawnPoint.global_position
