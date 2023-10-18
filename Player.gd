extends CharacterBody2D

## Actions
const IDLE_ACTION_NAME = "Idle"

const JUMP_ACTION_NAME = "Jump"
const MOVE_LEFT_ACTION_NAME = "Move_Left"
const MOVE_RIGHT_ACTION_NAME = "Move_Right"

enum States {JUMP, IDLE}
const STATES_ACTION_NAMES = [JUMP_ACTION_NAME, IDLE_ACTION_NAME]

var action_buffer: States = States.IDLE
var action: States = States.IDLE

@export var is_falling: bool = false
var is_moving_right = false
var is_moving_left = false
var is_jumping = false

#Physics
@export var MAX_SPEED: float = 150.0
@export var JUMP_V0: float = 100000.0
@export var FALL_GRAVITY_MULTIPLIER: float = 2

# 1 vingtième de seconde avant d'être à vitesse maximale
var time_full_speed: float = 1.0 / 20.0
var accel_x: float = MAX_SPEED / time_full_speed


@export var g: float = 980

var acceleration: Vector2 = Vector2(0, g)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

## Inputs
func process_inputs():
	is_moving_left = false
	is_moving_right = false

	if (is_jumping && is_on_floor()):
		is_jumping = false

	if (Input.is_action_just_pressed(JUMP_ACTION_NAME)):
		is_jumping = true

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
	velocity.y = JUMP_V0


## Physics
# Handles 
func process_physics(delta: float):
	acceleration.x = 0
	if (is_moving_left):
		acceleration.x = -accel_x

	if (is_moving_right):
		acceleration.x = accel_x

	if (Input.is_action_just_released(JUMP_ACTION_NAME)):
		velocity.y = JUMP_V0
		print(velocity, is_jumping)


	acceleration.y = g 

	if is_falling:
		acceleration.y = g * FALL_GRAVITY_MULTIPLIER

	

	if not is_on_floor():
		velocity.y += acceleration.y * delta


	if (acceleration.x == 0):
		velocity.x *= time_full_speed * delta

	velocity.x += acceleration.x * delta
	if (is_jumping):
		position += velocity * delta + acceleration * (delta ** 2) / 2

	if (velocity.x > MAX_SPEED):
		velocity.x = MAX_SPEED

	if (velocity.x < -MAX_SPEED):
		velocity.x = -MAX_SPEED

	move_and_slide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	# print(is_on_floor())
	print(is_moving_left, ' ', is_moving_right, ' ', velocity, ' ', is_jumping, ' ', acceleration)

	process_inputs()
	process_state()


	process_physics(delta)



