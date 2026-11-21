extends Node2D

signal battery_charge_changed(charge)

@export var light_source_width: float = 3.0
@export_category("Spread mode parameters")
@export var spread_mode_range: float = 64.0
@export_range(0.0001, 180.0) var spread_mode_angle:float = 120.0
@export_range(0.0, 1.0) var spread_mode_falloff:float
@export_range(0.0, 1.0) var spread_mode_angular_falloff:float
@export_category("Focus mode parameters")
@export var focus_mode_range: float = 128.0
@export_range(0.0001, 180.0) var focus_mode_angle:float = 10.0
@export_range(0.0, 1.0) var focus_mode_falloff:float
@export_range(0.0, 1.0) var focus_mode_angular_falloff:float
@export_category("Battery")
@export var spread_drain_rate: float = 0.6
@export var focused_drain_rate: float = 0.6
var maxBattery: float = 100.0
var battery: float = 100.0
var modes: Array[Texture2D]
var current_mode: int = 0 #0: off 1: Spread 2: Focus

var drain_rate: float = 0.0

@onready var spread_light = $SpreadLight
@onready var focus_light = $FocusLight
@onready var spread_hitbox = $Area2D/spreadBeamHitbox
@onready var focus_hitbox = $Area2D/focusBeamHitbox


func _enter_tree() -> void:
	check_and_load_beams()

func _ready() -> void:
	maxBattery = PlayerData.max_flashlight_battery
	battery = PlayerData.flashlight_battery
	make_beam_collision_boxes()
	spread_light.texture = modes[0]
	focus_light.texture = modes[1]
	spread_light.position.y = spread_mode_range/2
	focus_light.position.y = focus_mode_range/2

func _process(delta: float) -> void:
	if battery <= 0.0:
		set_off()
		return
	
	if Input.is_action_pressed("spray"):
		set_spread()
		drainBattery(delta)
	elif Input.is_action_pressed("focused"):
		set_focus()
		drainBattery(delta)
	else:
		set_off()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spray") or event.is_action_pressed("focused"):
		$SoundOn.play()
	elif event.is_action_released("spray") or event.is_action_released("focused"):
		$SoundOff.play()

func set_off() -> void:
	if current_mode == 0:
		return
	spread_light.enabled = false
	focus_light.enabled = false
	spread_hitbox.set_deferred("disabled", true)
	focus_hitbox.set_deferred("disabled", true)
	current_mode = 0
	drain_rate = 0.0
	
func set_spread() -> void:
	if current_mode == 1:
		return
	spread_light.enabled = true
	focus_light.enabled = false
	spread_hitbox.set_deferred("disabled", false)
	focus_hitbox.set_deferred("disabled", true)
	current_mode = 1
	drain_rate = focused_drain_rate

func set_focus() -> void:
	if current_mode == 2:
		return
	spread_light.enabled = false
	focus_light.enabled = true
	spread_hitbox.set_deferred("disabled", true)
	focus_hitbox.set_deferred("disabled", false)
	current_mode = 2
	drain_rate = spread_drain_rate

func drainBattery(delta: float) -> void:
	battery = max(0.0, battery - drain_rate * delta)
	PlayerData.set_flashlight_battery(battery)
	battery_charge_changed.emit(battery) 

func addBattery(amount: float) -> void:
	battery = min(maxBattery, battery + amount)
	PlayerData.set_flashlight_battery(battery)
	battery_charge_changed.emit(battery)

func make_beam_collision_boxes() -> void:
	var points_spread = create_beam_collision_box(spread_mode_range, spread_mode_angle, spread_mode_falloff, spread_mode_angular_falloff)
	spread_hitbox.shape = ConvexPolygonShape2D.new()
	spread_hitbox.shape.set_point_cloud(points_spread) 
	var points_focus = create_beam_collision_box(focus_mode_range, focus_mode_angle, focus_mode_falloff, focus_mode_angular_falloff)
	focus_hitbox.shape = ConvexPolygonShape2D.new()
	focus_hitbox.shape.set_point_cloud(points_focus)
	

func check_and_load_beams() -> void:
	var spread_name = "res://Overworld/Flashlight/" + "spread" + "_" + str(int(light_source_width)) + "_" + str(int(spread_mode_range)) + "_" + str(int(spread_mode_angle)) + "_" + str(int(spread_mode_falloff * 100)) + "_" + str(int(spread_mode_angular_falloff * 100)) + ".png"
	var focus_name = "res://Overworld/Flashlight/" + "focus" + "_" + str(int(light_source_width)) + "_" + str(int(focus_mode_range)) + "_" + str(int(focus_mode_angle)) + "_" + str(int(focus_mode_falloff * 100)) + "_" + str(int(focus_mode_angular_falloff * 100)) + ".png"
	# Check if these resources exist
	if ResourceLoader.exists(spread_name):
		ResourceLoader.load_threaded_request(spread_name)
	else:
		create_light_beam("spread", light_source_width, spread_mode_range, spread_mode_angle, spread_mode_falloff, spread_mode_angular_falloff)
		ResourceLoader.load_threaded_request(spread_name)
	if ResourceLoader.exists(focus_name):
		ResourceLoader.load_threaded_request(focus_name)
	else:
		create_light_beam("focus", light_source_width, focus_mode_range, focus_mode_angle, focus_mode_falloff, focus_mode_angular_falloff)
		ResourceLoader.load_threaded_request(focus_name)
	# Add the loaded resources as parts of the array
	modes.append(ResourceLoader.load_threaded_get(spread_name))
	modes.append(ResourceLoader.load_threaded_get(focus_name))

# Function to make a beam mask:
func create_light_beam(mode: String, source_width: float ,radius: float, angle_deg: float, falloff: float, angle_falloff: float):
	var angle = deg_to_rad(angle_deg)
	var R2: float
	if angle_deg > 179:
		R2 = 0
	else:
		R2 = source_width/ (2* tan(angle/2))
	var R_tot = radius + R2
	var H = int(ceil(radius))
	var W = int(ceil(2*R_tot*sin(angle/2)))
	
	var img = Image.create_empty(W,H,false,Image.Format.FORMAT_L8)
	
	# Make the image
	for y in range(H):
		for x in range(W):
			var r = sqrt(pow(x-(float(W)/2),2) + pow(y+R2,2))
			var theta = asin((x-(float(W)/2))/r)
			var p = 0.0
			if angle_falloff < 1.0 and falloff < 1.0:
				if r <= R2 + radius * falloff:
					if -(angle/2) <= theta and -(angle*angle_falloff/2) > theta:
						p = ((angle/2) + theta)/((angle/2)*(1-angle_falloff))
					elif -(angle*angle_falloff/2) <= theta and (angle*angle_falloff/2) >= theta:
						p = 1.0
					elif (angle*angle_falloff/2) < theta and (angle/2) >= theta:
						p = ((angle/2)-theta)/((angle/2)*(1-angle_falloff))
					else:
						p = 0.0
				elif r > R2 + radius * falloff and r <= R_tot:
					if -(angle/2) <= theta and -(angle*angle_falloff/2) > theta:
						p = (((angle/2) + theta)/((angle/2)*(1-angle_falloff))) * ((R_tot - r)/(R_tot*(1 - falloff)))
					elif -(angle*angle_falloff/2) <= theta and (angle*angle_falloff/2) >= theta:
						p = (R_tot - r)/(R_tot*(1 - falloff))
					elif (angle*angle_falloff/2) < theta and (angle/2) >= theta:
						p = (((angle/2)-theta)/((angle/2)*(1-angle_falloff))) * ((R_tot - r)/(R_tot*(1 - falloff)))
					else:
						p = 0.0
				else:
						p = 0.0
			elif angle_falloff < 1.0 and falloff == 1.0:
				if r <= R_tot:
					if -(angle/2) <= theta and -(angle*angle_falloff/2) > theta:
						p = ((angle/2) + theta)/((angle/2)*(1-angle_falloff))
					elif -(angle*angle_falloff/2) <= theta and (angle*angle_falloff/2) >= theta:
						p = 1.0
					elif (angle*angle_falloff/2) < theta and (angle/2) >= theta:
						p = ((angle/2)-theta)/((angle/2)*(1-angle_falloff))
					else:
						p = 0.0
				else:
						p = 0.0
			elif angle_falloff == 1.0 and falloff < 1.0:
				if -(angle/2) <= theta and (angle/2) >= theta:
					if r <= R2 + radius * falloff:
						p = 1.0
					elif r > R2 + radius * falloff and r <= R_tot:
						p = ((R_tot - r)/(R_tot*(1 - falloff)))
					else:
						p = 0.0
				else:
						p = 0.0
			else: #angle_falloff == 1.0 and falloff == 1.0
				if -(angle/2) <= theta and (angle/2) >= theta and r <= R_tot:
					p = 1.0
				else:
					p = 0.0
			var c = Color(p,p,p)
			img.set_pixel(x,y,c)
	# Save the image
	var image_name = "res://Overworld/Flashlight/" + mode + "_" + str(int(source_width)) + "_" + str(int(radius)) + "_" + str(int(angle_deg)) + "_" + str(int(falloff * 100)) + "_" + str(int(angle_falloff * 100)) + ".png"
	img.save_png(image_name)
	
		
# function to make a beam hitbox polygon
func create_beam_collision_box(radius: float, angle_deg: float, falloff: float, angle_falloff: float) -> PackedVector2Array:
	var angle = deg_to_rad(angle_deg)
	var angle_cutoff = angle * (1 - (1-angle_falloff)/2)
	var radius_cutoff = radius * (1 - (1-falloff)/2)
	var point_0 = Vector2(0.0,0.0)
	var point_1 = Vector2(-radius_cutoff * sin(angle_cutoff), radius_cutoff * cos(angle_cutoff))
	var point_2 = Vector2(-radius_cutoff * sin(angle_cutoff/2), radius_cutoff * cos(angle_cutoff/2))
	var point_3 = Vector2(0.0, radius_cutoff)
	var point_4 = Vector2(radius_cutoff * sin(angle_cutoff/2), radius_cutoff * cos(angle_cutoff/2))
	var point_5 = Vector2(radius_cutoff * sin(angle_cutoff), radius_cutoff * cos(angle_cutoff))
	var points = [point_0, point_1, point_2, point_3, point_4, point_5]
	return PackedVector2Array(points)
