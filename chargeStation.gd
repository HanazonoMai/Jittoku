extends StaticBody2D

@export var chargeRate: float = 2.5
var player : Node2D

var isCharging: bool = false
@export var maxChargeDistance: float = 300

@onready var interaction_box = $InteractionBox

@onready var clue_box = $ClueBox
@onready var clue_bubble = $clueBubble

var flashlight: Node


func interact() -> void:
	isCharging = true

func _process(delta: float) -> void:
	if player == null:
		player = get_node_or_null("../playerOverworld")
	if player == null:
		return
	if isCharging:
		if not Input.is_action_pressed("accept") or global_position.distance_to(player.global_position) > maxChargeDistance:
			isCharging = false
			return
		flashlight.addBattery(chargeRate * delta)
		
		if flashlight.battery >= flashlight.maxBattery:
			isCharging = false


func _on_clue_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		flashlight = get_tree().get_first_node_in_group("Flashlight")
		clue_bubble.visible = true


func _on_clue_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		clue_bubble.visible = false
