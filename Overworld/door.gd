extends StaticBody2D

@export var toUnlock := 1
var counter = 0

func _ready() -> void:
	unlock()

func _onFull():
	counter +=1
	unlock()
		

func unlock():
	if counter == toUnlock:
		$Sprite2D.play("open")
		$SoundUnlock.play()
		await $Sprite2D.animation_finished
		$CollisionShape2D.disabled = true
