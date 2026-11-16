extends PointLight2D

@export var modes: Array[GradientTexture2D] = []
var maxBattery: float = 100.0
@export var drainRate: float = 0.6
@export var battery: float = 100.0
var index: int = 0
@export var collision: CollisionShape2D

@export var chargeBar: ProgressBar



func _ready() -> void:
	#battery = maxBattery
	setOff()
	chargeBar.value = battery
	
func _process(delta: float) -> void:
	if battery <= 0.0:
		setOff()
		return
	
	if Input.is_action_pressed("spray"):
		setMode(0)
		collision.shape = load("res://arc collision.tres")
		drainBattery(delta)
	elif Input.is_action_pressed("focused"):
		setMode(1)
		collision.shape = load("res://line collision.tres")
		drainBattery(delta)
	else:
		setOff()

func setMode(newIndex: int) -> void:
	texture = modes[newIndex]

func setOff() -> void:
	texture = null
	collision.shape = null
	
func drainBattery(delta: float) -> void:
	battery = max(0.0, battery - drainRate * delta)
	chargeBar.value = battery

func addBattery(amount: float) -> void:
	battery = min(maxBattery, battery + amount)
	chargeBar.value = battery
