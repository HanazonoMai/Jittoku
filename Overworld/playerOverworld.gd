extends CharacterBody2D
class_name PlayerOverworld

@export var movementSpeed = 400
#@export var is_followed_by_merry: bool = false
@onready var flashlight: PointLight2D = $Pivot/Flashlight



var facingDirection = Vector2.RIGHT
var merry_scene = preload("res://Overworld/followerOverworld.tscn")


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray = $"Interaction detector"
@onready var rayReach = ray.target_position.length()
@onready var pivot = $Pivot
@export var follower: FollowerOverworld 

func _ready() -> void:
	# Checks if followed by Merry
#	sync_merry()
	#if PlayerData.followed_by_merry == true:
	#	summon_merry()
	pass
	

func _physics_process(_delta: float) -> void:
	movement()
	
	if Input.is_action_just_pressed("accept"):
		if ray.is_colliding():
			interact()


func interact():
	var target = ray.get_collider()
	target.interact()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	
	if mov != Vector2.ZERO:
		facingDirection = mov.normalized()
		ray.target_position = facingDirection * rayReach
		pivot.rotation = facingDirection.angle() - PI / 2
		var animToPlay: StringName
		if abs(mov.x) > abs(mov.y):
			animToPlay = &"walkSide"
			anim.flip_h = mov.x > 0
		elif mov.y < 0:
			animToPlay = &"walkUp"
		else:
			animToPlay = &"walkDown"
		if anim.animation != animToPlay or not anim.is_playing():
			anim.play(animToPlay)
			anim.frame = 1
		$Sounds/Footsteps.play_step()
	else:
		anim.frame = 0
		anim.stop()
	
	velocity = mov.normalized()*movementSpeed
	move_and_slide()

func transfer_global_position(new_global_position) -> void:
	global_position = new_global_position
	if follower != null:
		follower.global_position = global_position

#func sync_merry() -> void:
#	PlayerData.followed_by_merry = is_followed_by_merry

func summon_merry() -> void:
	var merry = merry_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(merry)
	merry.set_leader(self)
	merry.position = position
	follower = merry
	#is_followed_by_merry = true
	#sync_merry()


		
