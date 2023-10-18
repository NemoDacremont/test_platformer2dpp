extends CharacterBody2D

## Actions
const IDLE_ACTION_NAME = "Idle"

const DEFAULT_IN_AIR_ACCEL = 980


const JUMP_ACTION_NAME = "Jump"
const MOVE_LEFT_ACTION_NAME = "Move_Left"
const MOVE_RIGHT_ACTION_NAME = "Move_Right"

enum States {JUMP, IDLE}
const STATES_ACTION_NAMES = [JUMP_ACTION_NAME, IDLE_ACTION_NAME]

var action_buffer: States = States.IDLE
var action: States = States.IDLE

## Phsyique
@export var MAX_SPEED: float = 150.0
@export var JUMP_V0: float = 1000.0
@export var FALL_GRAVITY_MULTIPLIER: float = 2

@export var is_falling: bool = false
var is_moving_right = false
var is_moving_left = false
var is_jumping = false


@export var g: float = 980

var acceleration: Vector2 = Vector2(0, g)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

## Inputs
func process_inputs():
	if (Input.is_action_just_pressed(JUMP_ACTION_NAME)):
		is_jumping = true

	if (Input.is_action_just_pressed(MOVE_LEFT_ACTION_NAME)):
		is_moving_left= true

	if (Input.is_action_just_pressed(MOVE_RIGHT_ACTION_NAME)):
		is_moving_right = true


## State
# Is supposed to compute if the character is falling or more, state that isn't
# related to player's inputs
func process_state():
	if (velocity.y > 0):
		is_falling = true


## Physics
# Handles 
func process_physics(delta: float):
	# position += velocity * delta + acceleration * (delta ** 2) / 2
	acceleration.y = DEFAULT_IN_AIR_ACCEL
	if is_falling:
		acceleration = Vector2(0, g * FALL_GRAVITY_MULTIPLIER)

	

	if not is_on_floor():
		velocity += acceleration * delta



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# if (is_on_floor()):
	# 	velocity.y = 0

	# print(is_on_floor())
	print(velocity.y)

	process_inputs()
	process_state()


	process_physics(delta)
	move_and_slide()



