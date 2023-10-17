extends CharacterBody2D

## Actions
const IDLE_ACTION = "Idle"

const DEFAULT_IN_AIR_ACCEL = 980

var action_buffer: String = IDLE_ACTION
var action: String = IDLE_ACTION

## Phsyique
@export var MAX_SPEED: float = 150.0
@export var JUMP_V0: float = 1000.0
@export var FALL_GRAVITY_MULTIPLIER: float = 2
@export var is_falling: bool = false


@export var g: float = 980

var acceleration: Vector2 = Vector2(0, g)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

## Inputs



## Physics


func integrate_movement_verlet(delta: float):
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


	integrate_movement_verlet(delta)
	move_and_slide()



