extends StaticBody2D

@export var toUnlock := 1
var counter = 0

func _onFull():
	counter +=1
	if counter == toUnlock:
		$Sprite2D.play("open")
		$SoundUnlock.play()
		await $Sprite2D.animation_finished
		$CollisionShape2D.disabled = true
		
