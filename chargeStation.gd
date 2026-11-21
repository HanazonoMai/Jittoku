extends StaticBody2D

@export var chargeRate: float = .5
@onready var player = $"../playerOverworld"

var isCharging: bool = false
@export var maxChargeDistance: float = 300


func interact() -> void:
	isCharging = true

func _process(delta: float) -> void:
	player = get_node_or_null("../playerOverworld")
	if player == null:
		return
	if isCharging:
		if not Input.is_action_pressed("accept") or global_position.distance_to(player.global_position) > maxChargeDistance:
			isCharging = false
			return
		player.flashlight.addBattery(chargeRate * delta)
		
		if player.flashlight.battery >= player.flashlight.maxBattery:
			isCharging = false
