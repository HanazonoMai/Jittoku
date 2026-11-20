extends StaticBody2D

@export var toUnlock := 1
var counter = 0

func _onFull():
	counter +=1
	if counter == toUnlock:
		$Sprite2D.frame = 1
		$CollisionShape2D.disabled = true
		$SoundUnlock.play()
