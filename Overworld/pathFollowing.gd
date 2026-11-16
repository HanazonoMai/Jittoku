extends PathFollow2D

@export var speed = 225

func _process(delta):
	progress += speed * delta
