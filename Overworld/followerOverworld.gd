extends CharacterBody2D
class_name FollowerOverworld

@export var leader: PlayerOverworld = null
@export var follow_distance: float = 40.0 #The normal distance between the leader and the follower during walk, in pixels
@export var distance_to_leader: float = 20.0 #The distance to the leader when stopped

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray = $"Interaction detector"
@onready var rayReach = ray.target_position.length()
@onready var movementSpeed = leader.movementSpeed

var facingDirection = Vector2.RIGHT
var relativePositionOfLeader : Vector2
var currentDistanceToLeader: float
var leaderVelocity: Vector2
var cardinalDirection = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	check_leader_movement()
	movement()

func check_leader_movement() -> void:
	relativePositionOfLeader = leader.position - position
	currentDistanceToLeader = relativePositionOfLeader.length()
	leaderVelocity = leader.velocity
	

func movement():
	var mov = Vector2.ZERO
	if leaderVelocity.is_equal_approx(Vector2.ZERO):
		if currentDistanceToLeader > distance_to_leader:
			mov = relativePositionOfLeader
	else:
		if currentDistanceToLeader >= follow_distance:
			mov = relativePositionOfLeader
	var animToPlay: StringName
	if mov != Vector2.ZERO:
		facingDirection = mov.normalized()
		ray.target_position = facingDirection * rayReach
		
		if abs(mov.x) > abs(mov.y):
			animToPlay = &"walkSide"
			anim.flip_h = mov.x > 0
			if mov.x > 0:
				cardinalDirection = Vector2.RIGHT
			else:
				cardinalDirection = Vector2.LEFT
		elif mov.y < 0:
			animToPlay = &"walkUp"
			cardinalDirection = Vector2.UP
		else:
			animToPlay = &"walkDown"
			cardinalDirection = Vector2.DOWN
		if anim.animation != animToPlay or not anim.is_playing():
			anim.play(animToPlay)
			anim.frame = 1
		$Sounds/Footsteps.play_step()
	else:
		anim.frame = 0
		anim.stop()
		# if we add idle animations:
		#if cardinalDirection == Vector2.UP:
			#animToPlay = &"idleUp"
		#elif  cardinalDirection == Vector2.DOWN:
			#animToPlay = &"idleDown"
		#elif  cardinalDirection == Vector2.LEFT:
			#animToPlay = &"idleSide"
			#anim.flip_h = false
		#else:
			#animToPlay = &"idleSide"
			#anim.flip_h = true
		#if anim.animation != animToPlay or not anim.is_playing():
			#anim.play(animToPlay)
			#anim.frame = 1
		
			
	
	velocity = mov.normalized()*movementSpeed
	move_and_slide()
