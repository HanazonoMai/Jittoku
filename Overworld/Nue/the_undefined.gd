extends CharacterBody2D

const Sensor = preload("res://Overworld/sensor.gd")

@export var target: Node2D = null

enum Behavior {
	ROAMING = 0,
	DETECTED_SENSOR = 1,
	DETECTED_FLASHLIGHT = 2,
	STALKING = 3,
	ATTACKING = 4
}
@export var behavior: int = 0 #makeshift state machine

# 0: roaming
# 1: detected sensors being activated in her far sight, heading in its direction
# 2: detected flashlight beam in her far sight, proceeding toward them until the light turns off
# 3: detected players: stalking from afar
# 4: detected players: running on them and attacking

@export_category("Behavior properties")
@export var roaming_speed: float = 50
@export var roaming_lerp_speed: float = 3.0
@export var roaming_radius: float = 300.0
@export var roaming_timer_min: float = 2.0
@export var roaming_timer_max: float = 15.0
@export var time_needed_to_forget_the_flashlight: float = 5.0
@export var stalking_speed: float = 130
@export var stalking_lerp_speed: float = 8.0
@export var sprinting_speed: float = 500
@export var sprinting_lerp_speed: float = 10.0
@export var fast_looking_lerp_speed: float = 15.0
@export var sensor_observation_distance: float = 80.0
@export var sensor_observation_time: float = 2.0
@export var min_stalking_distance: float = 60.0 # below this: attack
@export var max_stalking_distance: float = 250.0 # above this: stop stalking
@export var outrunning_time: float = 10.0
@export var max_stalking_time_before_attack: float = 25.0
@export var attack_range: float = 50.0
@export_category("Interaction Range")
@export var solid_collision_radius: float = 30.0
@export var surroundings_detection_radius: float = 90.0
@export var far_detection_distance: float = 1500.0
@export var far_detection_spread: float = 400.0
@export var close_detection_distance: float = 500.0
@export var close_detection_spread: float = 200.0


@onready var solid_collision_box = $CloseDetectionArea/SolidCollision
@onready var far_detection_box = $FarDetectionArea/FarDetection
@onready var close_detection_box = $CloseDetectionArea/CloseDetection
@onready var surroundings_detection_box = $CloseDetectionArea/SurroundingsDetection

@onready var roaming_timer = $RoamingTimer
@onready var sensor_observation_timer = $SensorObservationTimer
@onready var flashlight_disinterest_timer = $FlashlightDisinterestTimer
@onready var outrunning_timer = $OutrunningTimer
@onready var stalking_timer = $StalkingTimer

var is_currently_outrun: bool

var current_speed: float = 100.0
var speed_regime: int = 0 #0 = roaming, 1 = investigating/stalking, 2 = sprinting
#var stopping: bool = false
var checked_sensors: Array[StaticBody2D] = []

var temporary_target_position: Vector2
var roaming_home_position: Vector2

var observing_sensor: bool = false

var flashlight_already_off: bool = false

var target_out_of_stalking_radius: bool = true
var stalking_phase: int = 0 #0 = approacking, 1 = retreating, 2 = standing by

var attack_launched: bool = false

func _ready() -> void:
	temporary_target_position = global_position
	find_all_sensors()
	hitbox_setup()
	start_roaming()
	call_deferred("find_player")

func _physics_process(delta: float) -> void:
	if behavior == 0:
		roaming(delta)
	if behavior == 1:
		checking_sensor(delta)
	if behavior == 2:
		checking_flashlight_beam(delta)
	if behavior == 3:
		stalking(delta)
	if behavior == 4:
		attacking_player(delta)
	move_forward_simple(delta)

func find_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var flashlight = player.get_node("Pivot/playerFlashlight")
		flashlight.connect("flashlight_on", notice_flashlight.bind(player))

var all_sensors = []
func find_all_sensors():
	var parent = get_parent()
	for c in parent.find_children("", "StaticBody2D"):
		if c.get_script() == Sensor:
			all_sensors.append(c)
			c.connect("full", notice_sensor.bind(c))

func notice_sensor(sensor : Node2D):
	start_checking_sensor(sensor)

func notice_flashlight(player : Node2D):
	target = player
	start_checking_flashlight_beam()

func hitbox_setup() -> void:
	var solid_shape = CircleShape2D.new()
	solid_shape.radius = solid_collision_radius
	solid_collision_box.shape = solid_shape
	var surroundings_detection_shape = CircleShape2D.new()
	surroundings_detection_shape.radius = surroundings_detection_radius
	surroundings_detection_box.shape = surroundings_detection_shape
	var close_detection_shape = ConvexPolygonShape2D.new()
	var point_c_0 = Vector2(0.0,- surroundings_detection_radius)
	var point_c_1 = Vector2(close_detection_distance, - close_detection_spread/2)
	var point_c_2 = Vector2(close_detection_distance, close_detection_spread/2)
	var point_c_3 = Vector2(0.0, surroundings_detection_radius)
	close_detection_shape.points = PackedVector2Array([point_c_0, point_c_1, point_c_2,point_c_3])
	close_detection_box.shape = close_detection_shape
	var far_detection_shape = ConvexPolygonShape2D.new()
	var point_f_0 = Vector2( 0.0, - solid_collision_radius)
	var point_f_1 = Vector2(far_detection_distance, - far_detection_spread/2)
	var point_f_2 = Vector2(far_detection_distance, far_detection_spread/2)
	var point_f_3 = Vector2( 0.0, solid_collision_radius)
	far_detection_shape.points = PackedVector2Array([point_f_0, point_f_1,point_f_2,point_f_3])
	far_detection_box.shape = far_detection_shape
	



### MOVEMENT FUNCTIONS ###
func move_to(delta: float, target_position: Vector2, stopping_distance: float = 25) -> void:
	if global_position.distance_squared_to(target_position) >= stopping_distance: # and stopping == false:
		#move to the point
		var target_angle = get_angle_to(target_position)
		var target_speed: float
		var lerp_speed: float
		if speed_regime == 0:
			target_speed = roaming_speed
			lerp_speed = roaming_lerp_speed
		elif speed_regime == 1:
			target_speed = stalking_speed
			lerp_speed = stalking_lerp_speed
		else:
			target_speed = sprinting_speed
			lerp_speed = sprinting_lerp_speed
		global_rotation = lerp(global_rotation, target_angle, delta * lerp_speed)
		current_speed = lerp(current_speed, target_speed, delta * lerp_speed)
		#var velocity = Vector2(current_speed,0).rotated(global_rotation)
	else:
		# stop the motion
		#stopping = true
		var lerp_speed: float
		if speed_regime == 0:
			lerp_speed = roaming_lerp_speed
		elif speed_regime == 1:
			lerp_speed = stalking_lerp_speed/2
		else:
			lerp_speed = sprinting_lerp_speed/5
		current_speed = lerp(current_speed, 0, delta * lerp_speed)

func look_at_target(delta: float, target_position: Vector2) -> void:
	var target_angle = get_angle_to(target_position)
	global_rotation = lerp(global_rotation,target_angle, delta * fast_looking_lerp_speed)

func move_forwards(delta: float) -> void:
	velocity = Vector2(current_speed,0).rotated(global_rotation)
	move_and_slide()

func move_forward_simple(delta: float):
	var amount = min(current_speed, global_position.distance_to(temporary_target_position))
	velocity = amount*(temporary_target_position-global_position).normalized()
	move_and_slide()

func retreat_backwards(delta: float, target_position: Vector2, stopping_distance: float) -> void:
	if global_position.distance_squared_to(target_position) <= stopping_distance: # and stopping == false:
		#look at target
		look_at_target(delta, target_position)
		var target_speed = - stalking_speed
		current_speed = lerp(current_speed, target_speed, delta * stalking_lerp_speed)
	else:
		#stop the motion
		#stopping = true
		look_at_target(delta, target_position)
		current_speed = lerp(current_speed, 0.0, delta * stalking_lerp_speed)

func stand_by(delta: float) -> void:
	pass
	#if is_equal_approx(current_speed, 0.0):
		#current_speed = 0.0
	#else:
		#var lerp_speed: float
		#if speed_regime == 0:
			#lerp_speed = roaming_lerp_speed
		#elif speed_regime == 1:
			#lerp_speed = stalking_lerp_speed
		#else:
			#lerp_speed = sprinting_lerp_speed
		#current_speed = lerp(current_speed, 0.0, delta * lerp_speed)
		

# Roaming	
func start_roaming() -> void:
	behavior = 0
	$Label.text = "Roaming"
	roaming_home_position = global_position
	speed_regime = 0
	current_speed = roaming_speed
	set_roaming_target()

func set_roaming_target() -> void:
	var random_r = randf() * roaming_radius
	var random_theta = 2 * PI * randf()
	temporary_target_position = roaming_home_position + random_r * Vector2(cos(random_theta), sin(random_theta))
	var random_roaming_time = roaming_timer_min + randf() * (roaming_timer_max - roaming_timer_min)
	#stopping = false
	roaming_timer.start(random_roaming_time)

func roaming(delta: float) -> void:
	pass
	# move_to(delta, temporary_target_position, 0)

# checking sensors
func start_checking_sensor(sensor: StaticBody2D) -> void:
	behavior = 1
	$Label.text = "Checking sensor"
	speed_regime = 0
	current_speed = roaming_speed
	checked_sensors.append(sensor)
	target = sensor
	var sensor_position = sensor.global_position
	var angle_to_sensor = get_angle_to(sensor_position)
	var rand_theta = angle_to_sensor + (PI/2) + randf()*PI
	temporary_target_position = sensor_position + sensor_observation_distance * Vector2(cos(rand_theta), sin(rand_theta))
	#stopping = false

func checking_sensor(delta: float) -> void:
	var d = global_position.distance_to(target.global_position)
	if d > 1.5* sensor_observation_distance:
		pass
		#move_to(delta, temporary_target_position, 0)
	else:
		stand_by(delta)
		#look_at_target(delta, target.global_position)
		#if observing_sensor == false:
		#	observing_sensor = true
		#	sensor_observation_timer.start(sensor_observation_time)
		start_roaming()

# checking flashlight beam
func start_checking_flashlight_beam() -> void:
	$Label.text = "Checking flashlight"
	behavior = 2
	speed_regime = 1
	current_speed = roaming_speed
	target = get_tree().get_first_node_in_group("player")
	temporary_target_position = target.global_position
	#stopping = false

func checking_flashlight_beam(delta: float) -> void:
	if PlayerData.flashlight_on == true:
		temporary_target_position = target.global_position
	else:
		var d = global_position.distance_to(temporary_target_position)
		if d < 90.0:
			start_roaming()
	
	
	
	
	var safety_distance = sqrt(pow(far_detection_distance,2) + pow(far_detection_spread,2))
	
	return
	#if PlayerData.flashlight_on == true:
		#if flashlight_already_off == true and d > safety_distance:
			#stand_by(delta)
		#else:
			#flashlight_already_off = false
			##move_to(delta,temporary_target_position,0)
	#else:
		#stand_by(delta)
		#if flashlight_already_off == false:
			#flashlight_already_off = true
			#flashlight_disinterest_timer.start(time_needed_to_forget_the_flashlight)
	

# stalking player
func start_stalking_player() -> void:
	behavior = 3
	$Label.text = "Stalking"
	speed_regime = 1
	current_speed = stalking_speed
	target = get_tree().get_first_node_in_group("player")
	temporary_target_position = target.global_position
	#var random_attack_time = outrunning_time + randf() * (max_stalking_time_before_attack - outrunning_time)
	#stalking_timer.start(random_attack_time)
	#stopping = false

func stalking(delta: float) -> void:
	temporary_target_position = target.global_position
	var d = global_position.distance_to(target.global_position)
	if d > max_stalking_distance:
		start_roaming()
	if d < min_stalking_distance:
		start_attacking_player()
	return
	#var ideal_radius = min_stalking_distance +(max_stalking_distance - min_stalking_distance)/2
	#if d >= max_stalking_distance:
		#if is_currently_outrun == false:
			#is_currently_outrun = true
			#outrunning_timer.start(outrunning_time)
		#stalking_phase = 0
		#move_to(delta,temporary_target_position,0)
	#elif d <= min_stalking_distance:
		#stalking_phase = 1
		#retreat_backwards(delta,temporary_target_position,max_stalking_distance)
	#else:
		#is_currently_outrun = false
		#if stalking_phase == 0:
			#if d <= ideal_radius:
				#stalking_phase = 2
				#stand_by(delta)
			#else:
				#move_to(delta,temporary_target_position,0)
		#elif stalking_phase == 1:
			#if d >= ideal_radius:
				#stalking_phase = 2
				#stand_by(delta)
			#else:
				#retreat_backwards(delta,temporary_target_position,max_stalking_distance)
		#else: # stalking phase == 2
			#stand_by(delta)
			#look_at_target(delta, temporary_target_position)
		
# attacking player
func start_attacking_player() -> void:
	behavior = 4
	$Label.text = "Attacking"
	speed_regime = 2
	current_speed = sprinting_speed
	target = get_tree().get_first_node_in_group("player")
	temporary_target_position = target.global_position

func attacking_player(delta: float) -> void:
	temporary_target_position = target.global_position
	return
	#var d = global_position.distance_to(temporary_target_position)
	#move_to(delta, temporary_target_position, 0)
	#if d <= attack_range and attack_launched == false:
		#attack()

func attack() -> void:
	attack_launched = true
	pass

func _on_roaming_timer_timeout() -> void:
	if behavior == 0:
		set_roaming_target()


func _on_outrunning_timer_timeout() -> void:
	if behavior == 3 and is_currently_outrun == true:
		target = null
		is_currently_outrun = false
		start_roaming()


func _on_stalking_timer_timeout() -> void:
	if behavior == 3:
		start_attacking_player()


func _on_flashlight_disinterest_timer_timeout() -> void:
	if behavior == 2 and flashlight_already_off == true:
		start_roaming()


func _on_sensor_observation_timer_timeout() -> void:
	if behavior == 1:
		start_roaming()


func _on_far_detection_area_area_entered(area: Area2D) -> void:
	# Detect charged sensors or flashlight beams
	var detected_object = area.get_parent()
	if detected_object.is_in_group("Sensor"):
		if detected_object.charge == 100 and checked_sensors.has(detected_object) == false:
			if behavior == 0:
				start_checking_sensor(detected_object)
	elif detected_object.is_in_group("Flashlight"):
		if behavior == 0 or behavior == 1:
			start_checking_flashlight_beam()


func _on_close_detection_area_area_entered(area: Area2D) -> void:
	# Detect charged sensors, flashlight beams or players
	var detected_object = area.get_parent()
	if detected_object.is_in_group("Sensor"):
		if detected_object.charge == 100 and checked_sensors.has(detected_object) == false:
			if behavior == 0:
				start_checking_sensor(detected_object)
	elif detected_object.is_in_group("Flashlight"):
		if behavior == 0 or behavior == 1:
			start_checking_flashlight_beam()
	elif detected_object.is_in_group("player"):
		if behavior == 0 or behavior == 1 or behavior == 2:
			start_stalking_player()
