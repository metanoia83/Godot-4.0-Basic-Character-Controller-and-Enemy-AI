extends CharacterBody3D

var target
var chase_speed = 10.0
var patrol_speed = 1.0
var move_state = 0
var patrol_range = 20
var direction = Vector3()
var anim = ANIM_IDLE
var patrolling = false
var chasing = false
var dead = false

@onready var player = get_tree().get_nodes_in_group("Player")[0]
@onready var camera = get_tree().get_nodes_in_group("Camera")[0]
@onready var animation = $EnemyMesh/AnimationTree
@onready var navigationagent = $NavigationAgent3D


const ANIM_IDLE = 0
const ANIM_PATROL = 1
const ANIM_CHASE = 2
const ANIM_DEAD = 3
const IDLE_BLEND_AMOUNT = 0.01

# STATES
var state
enum {IDLE, PATROL, CHASE, DEAD}

func _ready():
	
	#INITIAL STATE
	change_state(IDLE)
	
	# PATROL TIMER START
	$Timer.start()
	
	# RANDOMIZE PATROL POINTS
	randomize()
	
func _physics_process(delta):
	
	# RUNS ENEMY ANIMATION
	animate()
	
	# HANDLES CHASING
	if target and not dead:
		if chasing:
			chasing_player(delta)
			var next_path_position = navigationagent.get_next_path_position()
			var direction = global_position
			var new_velocity = (next_path_position - direction).normalized() * chase_speed
			navigationagent.set_velocity(new_velocity)
			rotation.x = 0
			rotation.y = lerp_angle(rotation.y, atan2(new_velocity.x,new_velocity.z), delta * 5.0)
			
	# HANDLES PATROLLING
	else:
		if navigationagent.is_target_reachable() and target == null and not state == IDLE:
			var next_path_position = navigationagent.get_next_path_position()
			var direction = global_position
			var new_velocity = (next_path_position - direction).normalized() * patrol_speed
			navigationagent.set_velocity(new_velocity)

			if patrolling:
				target = null
				rotation.x = 0
				rotation.y = lerp_angle(rotation.y, atan2(new_velocity.x,new_velocity.z), delta * 1.5)
				
				
# FUNCTION FOR CHASING
func chasing_player(delta):
	navigationagent.set_target_position(player.global_position)

# FUNCTION FOR PATROLLING
func patrolling_to(target_pos):
	target = null
	navigationagent.set_target_position(target_pos) 

# PATROLLING AREA RANGE
func get_random_pos_in_sphere (radius : float) -> Vector3:
	var x1 = randf_range (-1, 1)
	var x2 = randf_range (-1, 1)

	while x1*x1 + x2*x2 >= 1:
		x1 = randf_range (-1, 1)
		x2 = randf_range (-1, 1)

	var random_pos_on_unit_sphere = Vector3 (
	2 * x1 * sqrt (1 - x1*x1 - x2*x2),
	2 * x2 * sqrt (1 - x1*x1 - x2*x2),
	1 - 2 * (x1*x1 + x2*x2))

	return random_pos_on_unit_sphere * randf_range (0, radius)
	
# HANDLES STATE
func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			anim = ANIM_IDLE
		PATROL:
			anim = ANIM_PATROL
		CHASE:
			anim = ANIM_CHASE
		DEAD:
			anim = ANIM_DEAD

# HANDLES ANIMATION
func animate():
	
	# PATROLLING STATE
	if patrolling:
		change_state(PATROL)
	
	# CHASING STATE
	if chasing:
		change_state(CHASE)
		move_state -= IDLE_BLEND_AMOUNT
	
	# IDLE STATE
	if !chasing and !patrolling:
		change_state(IDLE)
		move_state -= IDLE_BLEND_AMOUNT
		
	# DEAD STATE
	if dead:
		change_state(DEAD)
	
	# CLAMP BLEND FOR IDLE - WALK
	move_state = clamp(move_state, 0, 1)
	
	# ANIMATIONTREE BLEND
	animation["parameters/Blend2/blend_amount"]=move_state
	animation["parameters/Blend3/blend_amount"]=move_state
	
	# ANIMATIONTREE TRANSITION
	if animation.get("parameters/state/current_index") != anim:
		animation["parameters/state/transition_request"]="state " + str(anim)

# START OF PATROLLING
func _on_timer_timeout():
	patrolling = true
	chasing = false
	
	if target == null:
		var random_position = Vector3(get_random_pos_in_sphere(patrol_range).x,0,get_random_pos_in_sphere(patrol_range).z) + get_position()
		patrolling_to(random_position)

# MAKE THE ENEMY MOVE
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

# DETECTION AREA - PLAYER IS NEARBY
func _on_player_detection_body_entered(body):
	if body.is_in_group("Player"):
		target = body
		patrolling = false
		chasing = true
		$Timer.stop()
# DETECTION AREA - PLAYER IS FAR (CHANGE TO IDLE THEN PATROLLING)
func _on_player_detection_body_exited(body):
	if body.is_in_group("Player"):
		target = null
		chasing = false
		patrolling = false
		$Timer.start()

