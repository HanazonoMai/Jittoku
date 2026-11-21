extends Area2D
class_name Gap

@export var open := true:
	set(value):
		open = value
		set_state()

@export var teleport_target : Node

## Where the gap runs to if lit. If not assigned, it just closes.
@export var flee_target : Node
## How long it stays closed/moved
@export var flee_time := 5.0

var sleep_time = 0.0

var original_position := Vector2(0,0)

var maxCharge = 25
@export var charge :float = 0
@export var fillSpeed: float = 50
var bodiesInZone: int = 0

func _ready():
	original_position = position
	set_state()

func _process(delta: float) -> void:
	if sleep_time > 0.0:
		sleep_time -= delta
		if sleep_time < 0.0:
			sleep_time = 0.0
	if bodiesInZone > 0:
		charge += fillSpeed * delta
	else:
		charge -= fillSpeed * delta
	charge = clamp(charge, 0, maxCharge)
	if charge >= maxCharge:
		charge = maxCharge
		#full.emit()
		flee()
		#$PointLight2D.visible = true

func set_state():
	if open:
		$Sprite2D.show()
		$PointLight2D.show()
	else:
		$Sprite2D.hide()
		$PointLight2D.hide()

## turn off teleportation without closing
func sleep(how_long := 3.0):
	sleep_time = how_long

func is_sleeping():
	return sleep_time > 0.0

func flee():
	if flee_target:
		move(flee_target.position)
		await get_tree().create_timer(flee_time).timeout
		move(original_position)
	else:
		flee_hide()

func flee_hide(how_long := -1.0):
	open = false
	emit_briefly()
	if how_long < 0.0:
		how_long = flee_time
	await get_tree().create_timer(how_long).timeout
	emit_briefly()
	open = true

func move(to : Vector2):
	open = false
	$Particles.emitting = true
	var tween = create_tween()
	tween.tween_property(self, "position", to, 0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$Particles.emitting = false
	open = true

func teleport(character : Node2D, to : Vector2):
	sleep()
	var temp_original_position = position
	open = false
	$Particles.emitting = true
	var tween = create_tween()
	tween.tween_property(self, "position", to, 0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$Particles.emitting = false
	character.position = to
	position = temp_original_position
	open = true

func emit_briefly(how_long := 0.5):
	$Particles.emitting = true
	await get_tree().create_timer(how_long).timeout
	$Particles.emitting = false

func _onInnerEntered(_body: Node2D) -> void:
	if not open or is_sleeping():
		return
	if _body.is_in_group("player"): # TODO: or Nue
		print("Player entered gap")
		if teleport_target:
			if teleport_target is Gap:
				teleport_target.sleep()
			teleport(_body, teleport_target.position)


func _onOuterEntered(_body: Node2D) -> void:
	bodiesInZone += 1
	print("Entered. Bodies in zone: ", bodiesInZone)
	$SoundActivate.play()
func _onOuterExited(_body: Node2D) -> void:
	bodiesInZone = max(0, bodiesInZone - 1)
	print("Exited. Bodies in zone: ", bodiesInZone)


func unload():
	charge = 0
