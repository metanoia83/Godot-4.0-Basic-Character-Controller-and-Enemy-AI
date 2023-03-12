extends CharacterBody3D

const JUMP_VELOCITY = 15
const ANIM_IDLERUN = 0
const KNOCKBACKJUMP = 20
const ANIM_JUMP = 1
const ANIM_DEAD= 2
const RUN_BLEND_AMOUNT = 0.2
const IDLE_BLEND_AMOUNT = 0.08
const JUMP_BLEND_AMOUNT = 0.15

var anim = ANIM_IDLERUN
var speed = 12.0
var move_state = 0
var jump_state = 0
var moving = false
var jumping = false
var dead = false
var gravity = 30
var lastPos = Vector3()
var direction = Vector3()

@onready var camera = get_tree().get_nodes_in_group("Camera")[0]
@onready var spawn = get_tree().get_nodes_in_group("Spawn")[0]
@onready var animation = $Boy/AnimationTree

var state
enum {IDLERUN, JUMP, DEAD}


func _ready():
	# HANDLES MOUSE CURSOR TO BE HIDDEN
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	change_state(IDLERUN)
	

func _physics_process(delta):
	animate()
	knockback()
	
	# HANDLES GRAVITY & PREVENT CHARACTER FROM TILTING WHEN JUMPING
	if not is_on_floor():
		velocity.y -= gravity * delta
		rotation.x = 0
		rotation.z = 0
		jumping = true
	else:
		jumping = false
		
	# HANDLES JUMP
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !dead:
		velocity.y = JUMP_VELOCITY
		

	# HANDLES INPUT DIRECTION BASE ON THE CAMERA BASIS
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and !dead:
		moving = true
		move_state += RUN_BLEND_AMOUNT
		
		# HANDLES THE ROTATION OF THE CHARACTER
		var t = transform
		var speed1 = Vector2(t.origin.x,t.origin.z).distance_to(Vector2(lastPos.x,lastPos.z))
		var rotTransform
		var thisRotation
		
		if (speed1 >= 0.007):
			rotTransform = t.looking_at(lastPos, Vector3.UP)
			thisRotation = Quaternion(t.basis.orthonormalized()).slerp(rotTransform.basis.orthonormalized(), 0.08)
			transform = Transform3D(thisRotation, t.origin)
			lastPos = t.origin
			
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# PREVENT THE CHARACTER FROM TILTING WHEN ON WALL
		if is_on_wall():
			rotation.x = 0
			rotation.z = 0

		
	else:
		# MAKES THE CHARACTER STOP
		move_state -= IDLE_BLEND_AMOUNT
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		rotation.x = 0
		rotation.z = 0
		moving = false

	move_and_slide()

# KNOCKBACK WHEN CHARACTER JUMPS ON ENEMIES
func knockback():
	if ($KnockBack.is_colliding() and $KnockBack.get_collider().is_in_group("Enemy")):
		velocity.y = KNOCKBACKJUMP
		var knockback = $KnockBack.get_collider()
		knockback.dead = true
		knockback.chase_speed = 0
		knockback.patrol_speed = 0
		knockback.get_node("Timer").stop()
		knockback.patrolling = false
		knockback.chasing = false
		knockback.target = null


# HANDLES THE STATE CHANGE
func change_state(new_state):
	state = new_state
	match state:
		IDLERUN:
			anim = ANIM_IDLERUN
		JUMP:
			anim = ANIM_JUMP
		DEAD:
			anim = ANIM_DEAD

# HANDLES THE ANIMATION
func animate():

	# ANIMATION FROM IDLE TO RUN & RUN TO IDLE
	if (moving and !jumping) or (!moving and !jumping):
		change_state(IDLERUN)
		
	if dead:
		change_state(DEAD)
		
	# ANIMATION FROM JUMP UP TO LANDING
	if jumping and !is_on_floor():
		change_state(JUMP)
		
		if velocity.y < 0:
			# JUMP UP
			jump_state += JUMP_BLEND_AMOUNT
		else:
			# LANDING
			jump_state -= JUMP_BLEND_AMOUNT
	
	# CLAMP BLEND FOR IDLE > RUN & RUN > IDLE
	move_state = clamp(move_state, 0, 1)
	
	# CLAMP BLEND FOR JUMP UP > LANDING
	jump_state = clamp(jump_state, 0, 1)
	
	# ANIMATIONTREE BLEND
	animation["parameters/Blend2/blend_amount"]=move_state
	animation["parameters/Blend3/blend_amount"]=jump_state
	
	# ANIMATIONTREE TRANSITION
	if animation.get("parameters/state/current_index") != anim:
		animation["parameters/state/transition_request"]= "state " + str(anim)

# RESPAWN CHARACTER AFTER DEATH
func _on_death_timer_timeout():
	change_state(IDLERUN)
	get_tree().get_root().set_disable_input(false)
	dead = false
	set_global_transform(spawn.get_global_transform()) 
