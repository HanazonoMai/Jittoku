extends StaticBody2D

var maxCharge = 100
@export var charge :float = 0
@export var fillSpeed: float = 50
var bodiesInZone: int = 0

@export var pitchUp := 1.0
@export var soundLoopTime := 1.5
@export var door: StaticBody2D

signal full
#signal unloaded

func _ready():
	$Pluck/Timer.wait_time = soundLoopTime

func _process(delta: float) -> void:
	if charge == maxCharge:
		return


	if bodiesInZone > 0:
		charge += fillSpeed * delta
		if charge >= 100:
			charge = 100
			full.emit()
			$PointLight2D.visible = true
		if not $Pluck.playing:
			$Pluck.pitch_scale = 1.0 + pitchUp*charge/maxCharge

func _onAreaEntered(_body: Node2D) -> void:
	bodiesInZone += 1
	print("Entered. Bodies in zone: ", bodiesInZone)
func _onAreaExited(_body: Node2D) -> void:
	bodiesInZone = max(0, bodiesInZone - 1)
	print("Exited. Bodies in zone: ", bodiesInZone)


func unload():
	if charge == maxCharge:
		door.counter =-1 
		if door.counter < 0:
			door.counter = 0
	charge = 0
	$PointLight2D.visible = false
	

	
