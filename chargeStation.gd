extends StaticBody2D

@export var chargeRate: float = .5
@onready var player = Game.player

var isCharging: bool = false

func interact() -> void:
	isCharging = true

func _process(delta: float) -> void:
	if isCharging:
		player.flashlight.addBattery(chargeRate * delta)
		
		if player.flashlight.battery >= player.flashlight.maxBattery:
			isCharging = false
