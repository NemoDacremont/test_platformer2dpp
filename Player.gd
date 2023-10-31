extends CharacterBody2D

## Actions
const IDLE_ACTION_NAME = "Idle"

const JUMP_ACTION_NAME = "Jump"
const MOVE_LEFT_ACTION_NAME = "Move_Left"
const MOVE_RIGHT_ACTION_NAME = "Move_Right"

# States
enum States {JUMP, IDLE, WALL_JUMP, DEFAULT=IDLE}
const STATES_ACTION_NAMES = [JUMP_ACTION_NAME, IDLE_ACTION_NAME, "Wall_Jump"]

# Actions
var action_buffer: States = States.DEFAULT
const ACTION_BUFFER_TIMER_DURATION = 0.1
const COYOTE_JUMP_DURATION = 0.1
const COYOTE_JUMP_EPSILON = 5
var is_coyote_available = false

var next_action: States = States.DEFAULT
var is_action_busy: bool = true

# Nodes
var action_buffer_timer: Timer;
var left_wall_jump_timer: Timer
var right_wall_jump_timer: Timer
var animation_node: AnimatedSprite2D
var coyote_jump_node: Timer

@export var is_falling: bool = false
var is_right_wall_jumping: bool = false
var is_wall_jumping: bool = false
var is_left_wall_jumping: bool = false
var is_moving_right: bool = false
var is_moving_left: bool = false
var is_jumping: bool = false

#Physics
@export var g: float = 980
# v = 0 <=> t_max = v_0 / g, y(t_max) = v_0 ** 2 / (2 * g)
# tile_height = 18px, jump 5 -> v_0 = sqrt(2 * g * 5 * tile_height)
const TILE_HEIGHT = 18
const TILE_WIDTH = 18
const JUMP_TILE_HEIGHT_MULTIPLIER = 5
const JUMP_TILE_WIDTH_MULTIPLIER = 5
@export var JUMP_V0: float = -sqrt(2.0 * g * JUMP_TILE_HEIGHT_MULTIPLIER * TILE_HEIGHT)
@export var FALL_GRAVITY_MULTIPLIER: float = 2

# Store the velocity of last cycle
var last_velocity: Vector2 = Vector2.ZERO

const RIGHT_WALL_JUMP_TIMER_DURATION = 0.1
const LEFT_WALL_JUMP_TIMER_DURATION = 0.1
var WALL_JUMP_VY = -g / 3

@export var MAX_SPEED: float = JUMP_TILE_WIDTH_MULTIPLIER * TILE_WIDTH * g / abs(JUMP_V0)

# 1 vingtième de seconde avant d'être à vitesse maximale
var time_full_speed: float = 1.0 / 20.0
var accel_x: float = MAX_SPEED / time_full_speed

var acceleration: Vector2 = Vector2(0, g)

##
## Tests frottements
##
# 3 pour atteindre 3 t_0 (95% du régime transitoire)
var f = 1 / time_full_speed


##

# Animations
const JUMP_ANIMATION_NAME: String = "Jump"
const IDLE_ANIMATION_NAME: String = "Idle"
const WALK_ANIMATION_NAME: String = "Walk"
const JUMP_MID_JUMP_ANIMATION_EPSILON = 100



# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = Vector2.ZERO
	action_buffer_timer = $Action_Buffer_Timer
	animation_node = $Animations
	left_wall_jump_timer = $Left_Wall_Jump_Timer
	right_wall_jump_timer = $Right_Wall_Jump_Timer
	coyote_jump_node = $Coyote_Jump_Timer

	print("JUMP_V0: ", JUMP_V0)
	print("MAX_SPEED: ", MAX_SPEED)

## Animations
func process_animations():
	# Flip according to direction
	if (velocity.x < 0):
		animation_node.flip_h = true
	if (velocity.x > 0):
		animation_node.flip_h = false

	# If at the top if the jump
	if ((is_jumping || is_falling) && abs(velocity.y) < JUMP_MID_JUMP_ANIMATION_EPSILON):
		animation_node.play(JUMP_ANIMATION_NAME)
		animation_node.frame = 1
		return


	if (is_falling):
		animation_node.play(JUMP_ANIMATION_NAME)
		animation_node.frame = 2

		return


	if (is_jumping):
		animation_node.play(JUMP_ANIMATION_NAME)
		animation_node.frame = 0

	elif (is_moving_left):
		animation_node.play(WALK_ANIMATION_NAME)

	elif (is_moving_right):
		animation_node.play(WALK_ANIMATION_NAME)

	else:
		animation_node.play(IDLE_ANIMATION_NAME)

	


## Inputs
func process_inputs():
	is_moving_left = false
	is_moving_right = false

	if (is_jumping):
		if (is_on_floor()):
			action_buffer_timer.stop()
			is_jumping = false
			next_action = action_buffer
			action_buffer = States.DEFAULT


	if (Input.is_action_just_pressed(JUMP_ACTION_NAME)):
		# Wall jump if on wall
		if (is_on_wall_only()):
			next_action = States.WALL_JUMP

		# if during a jump, buffer it
		elif (is_jumping):
			action_buffer = States.JUMP
			action_buffer_timer.start(ACTION_BUFFER_TIMER_DURATION)

		# jump
		else:
			next_action = States.JUMP


	if (Input.is_action_pressed(MOVE_LEFT_ACTION_NAME)):
		is_moving_left= true

	if (Input.is_action_pressed(MOVE_RIGHT_ACTION_NAME)):
		is_moving_right = true



## State
# Is supposed to compute if the character is falling or more, state that isn't
# related to player's inputs
func process_state():
	is_falling = false

	if (abs(last_velocity.y) <= COYOTE_JUMP_EPSILON && abs(velocity.y) >= COYOTE_JUMP_EPSILON):
		is_coyote_available = true
		coyote_jump_node.start()

	
	if (velocity.y > 0):
		is_falling = true


func jump():
	is_jumping = true
	velocity.y = JUMP_V0
	print(JUMP_V0)


func wall_jump():
	velocity.y = JUMP_V0
	is_jumping = true

	# eps = 1 si on va vers la gauche, -1 sinon (va dans la direction opposé de la direction)
	var eps = 1
	if (is_moving_right):  # va vers la droite
		eps = -1

	velocity.x = eps * MAX_SPEED


	if (is_moving_right):  # va vers la droite
		is_right_wall_jumping = true
		right_wall_jump_timer.start()

	elif (is_moving_left):
		is_left_wall_jumping = true
		left_wall_jump_timer.start()




func process_action():
	match next_action:
		States.JUMP:
			if (is_on_floor() or is_coyote_available):
				jump()
		States.WALL_JUMP:
			if (is_on_wall_only()):
				wall_jump()
		_:
			pass

	next_action = States.DEFAULT


## Physics
# Handles 
func process_physics(delta: float):
	process_action()

	acceleration.x = 0

	if (not is_wall_jumping):
		if (is_moving_left):
			acceleration.x = -accel_x
		if (is_moving_right):
			acceleration.x = accel_x

	if (is_moving_left and (not is_left_wall_jumping and is_right_wall_jumping)):
		acceleration.x = -accel_x

	if (is_moving_right and (not is_right_wall_jumping and is_left_wall_jumping)):
		acceleration.x = accel_x


	acceleration.y = g 

	if is_falling:
		acceleration.y = g * FALL_GRAVITY_MULTIPLIER

	
	last_velocity = velocity
	if not is_on_floor():
		velocity.y += acceleration.y * delta


	if (acceleration.x == 0 && not is_wall_jumping):
		velocity.x *= time_full_speed * delta

	if (not is_wall_jumping):
		velocity.x = acceleration.x * delta + velocity.x * (1 - f * delta)

	# if (is_jumping):
	# 	position += velocity * delta + acceleration * (delta ** 2) / 2


	move_and_slide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	is_wall_jumping = is_left_wall_jumping or is_right_wall_jumping
	print(is_wall_jumping)

	process_animations()

	process_inputs()
	process_state()


	process_physics(delta)





func _on_action_buffer_timer_timeout():
	action_buffer = States.DEFAULT



func _on_right_wall_jump_timer_timeout():
	is_right_wall_jumping = false


func _on_coyote_jump_timer_timeout():
	is_coyote_available = false


func _on_left_wall_jump_timer_timeout():
	is_left_wall_jumping = false


