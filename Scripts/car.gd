extends CharacterBody3D

const BASE_SPEED = 5.0
const DRIFT_SPEED = 5.0 # Faster sideways movement when drifting
var steering_input = 0.0
var current_yaw = 0.0 # How fast the car rotates when holding a key
@export var turn_sensitivity = 2.0
@export var drift_amount = 1.0

func _physics_process(delta: float) -> void:
	steering_input = Input.get_axis("ui_left", "ui_right")
	var is_drifting = Input.is_action_pressed("ui_select")
		
	var current_speed = DRIFT_SPEED if is_drifting else  BASE_SPEED 

	# ACCUMULATE ROTATION
	current_yaw -= steering_input * turn_sensitivity * delta
	rotation.y = current_yaw
	
	# CALCULATE DIRECTION
	var forward_vector = -transform.basis.z 
	velocity.x = forward_vector.x * current_speed * (1 + drift_amount * int(is_drifting))
	
	# Visuals: Tilt the car into the turn
	var target_tilt = -steering_input * 0.05
	rotation.y = lerp_angle(rotation.y, target_tilt, 1.5 * delta)
	
	# Force Z to stay at zero
	velocity.z = 0
	move_and_slide()
