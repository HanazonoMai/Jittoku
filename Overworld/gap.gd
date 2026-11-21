extends Area2D
class_name Gap

@export var open := true:
	set(value):
		var changed := open != value
		open = value
		refresh_state(changed)

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

var monitored_follower: FollowerOverworld = null

func _ready():
	original_position = position
	refresh_state(false)

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

func refresh_state(changed := true):
	if open:
		if changed:
			$Sounds/Open.play()
		$Sprite2D.show()
		$PointLight2D.show()
	else:
		if changed:
			$Sounds/Close.play()
		$Sprite2D.hide()
		$PointLight2D.hide()

## turn off teleportation without closing
func sleep(how_long := 1.5):
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
	$Sounds/Flee.play()
	var tween = create_tween()
	tween.tween_property(self, "position", to, 0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$Particles.emitting = false
	open = true

func teleport(character : Node2D, to : Vector2):
	sleep()
	var temp_original_position = position
	open = false
	character.set_process(false)
	character.hide()
	$Particles.emitting = true
	$Sounds/Teleport.play()
	var tween = create_tween()
	tween.tween_property(self, "position", to, 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(character, "position", to, 0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$Particles.emitting = false
	character.position = to
	character.show()
	character.set_process(true)
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
			if _body.follower != null:
				#move the follower to the gap and get them teleported
				monitored_follower = _body.follower
				monitored_follower.set_independent_movement_target(global_position)
				monitored_follower.independent_movement_position_reached.connect(_on_follower_inside_the_gap)

func _on_follower_inside_the_gap() -> void:
	teleport(monitored_follower, teleport_target.position)
	print("teleporting Merry")
	monitored_follower.independent_movement_position_reached.disconnect(_on_follower_inside_the_gap)
	monitored_follower.reunite_with_leader()
	monitored_follower = null

func _onOuterEntered(_body: Node2D) -> void:
	bodiesInZone += 1
	print("Entered. Bodies in zone: ", bodiesInZone)
	$SoundActivate.play()
func _onOuterExited(_body: Node2D) -> void:
	bodiesInZone = max(0, bodiesInZone - 1)
	print("Exited. Bodies in zone: ", bodiesInZone)


func unload():
	charge = 0
