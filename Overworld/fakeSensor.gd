extends StaticBody2D

var maxCharge = 100
@export var charge :float = 0
@export var fillSpeed: float = 50
var bodiesInZone: int = 0

signal full

func _process(delta: float) -> void:
	if charge == maxCharge:
		return
		
	if bodiesInZone > 0:
		charge += fillSpeed * delta
		if charge >= 100:
			full.emit()
			unload()

func _onAreaEntered(_body: Node2D) -> void:
	bodiesInZone += 1
	print("Entered. Bodies in zone: ", bodiesInZone)
func _onAreaExited(_body: Node2D) -> void:
	bodiesInZone = max(0, bodiesInZone - 1)
	print("Exited. Bodies in zone: ", bodiesInZone)


func unload():
	charge = 0
