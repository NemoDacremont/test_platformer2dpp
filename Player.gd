extends CharacterBody2D

## Actions
const IDLE_ACTION_NAME = "Idle"

const JUMP_ACTION_NAME = "Jump"
const MOVE_LEFT_ACTION_NAME = "Move_Left"
const MOVE_RIGHT_ACTION_NAME = "Move_Right"

enum States {JUMP, IDLE, WALL_JUMP, DEFAULT=IDLE}
const STATES_ACTION_NAMES = [JUMP_ACTION_NAME, IDLE_ACTION_NAME, "Wall_Jump"]

var action_buffer: States = States.DEFAULT
var action_buffer_timer: Timer;
const ACTION_BUFFER_TIMER_DURATION = 0.1

var next_action: States = States.DEFAULT
var is_action_busy: bool = true

@export var is_falling: bool = false
var is_wall_jumping: bool = false
var is_moving_right: bool = false
var is_moving_left: bool = false
var is_jumping: bool = false

#Physics
@export var g: float = 980
@export var MAX_SPEED: float = 200.0
@export var JUMP_V0: float = -g / 2
@export var FALL_GRAVITY_MULTIPLIER: float = 2

var wall_jump_timer: Timer
const WALL_JUMP_TIMER_DIRATION = 0.1
var WALL_JUMP_VY = -g / 3

# 1 vingtième de seconde avant d'être à vitesse maximale
var time_full_speed: float = 1.0 / 20.0
var accel_x: float = MAX_SPEED / time_full_speed

# Animations
const JUMP_ANIMATION_NAME: String = "Jump"
const IDLE_ANIMATION_NAME: String = "Idle"
const WALK_ANIMATION_NAME: String = "Walk"

var animation_node: AnimatedSprite2D


var acceleration: Vector2 = Vector2(0, g)



##
## Tests frottements
##
var f = 30


##



# Called when the node enters the scene tree for the first time.
func _ready():
	action_buffer_timer = $Action_Buffer_Timer
	animation_node = $Animations
	wall_jump_timer = $Wall_Jump_Timer

## Animations
func process_animations():
	# Flip according to direction
	animation_node.flip_h = velocity.x < 0


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
			print("Reach floor and action_buffer=", action_buffer)
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
	
	if (velocity.y > 0):
		is_falling = true


func jump():
	is_jumping = true
	velocity.y = JUMP_V0


func wall_jump():
	velocity.y = JUMP_V0
	velocity.x = -MAX_SPEED
	is_wall_jumping = true
	wall_jump_timer.start(WALL_JUMP_TIMER_DIRATION)


func process_action():
	match next_action:
		States.JUMP:
			if (is_on_floor()):
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

		elif (is_moving_right):
			acceleration.x = accel_x


	acceleration.y = g 

	if is_falling:
		acceleration.y = g * FALL_GRAVITY_MULTIPLIER

	

	if not is_on_floor():
		velocity.y += acceleration.y * delta


	if (acceleration.x == 0 && not is_wall_jumping):
		velocity.x *= time_full_speed * delta

	velocity.x = acceleration.x * delta + velocity.x * (1 - f * delta)
	# if (is_jumping):
	# 	position += velocity * delta + acceleration * (delta ** 2) / 2


	move_and_slide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_animations()

	process_inputs()
	process_state()


	process_physics(delta)





func _on_action_buffer_timer_timeout():
	action_buffer = States.DEFAULT



func _on_wall_jump_timer_timeout():
	print("Wall jump timeout")
	is_wall_jumping = false

