extends CharacterBody3D

const BASE_SPEED = 5.0
const DRIFT_SPEED = 6.0

const BASE_STEERING_SENSITIVITY = 1.0
const DRIFT_STEERING_SENSITIVITY = 0.75

var steering_input = 0.0
var current_yaw = 0.0 
@export var turn_sensitivity = 2.0

# Logic for tracking the "First Pressed" key
var first_pressed_dir = 0.0

func _physics_process(delta: float) -> void:
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	
	# 1. DETECT THE "FIRST PRESSED" DIRECTION
	if left and right:
		# If both are held, stay with the one we already picked
		if first_pressed_dir == 0.0:
			# This only runs the very first frame both are pressed
			first_pressed_dir = 1.0 if Input.is_action_just_pressed("ui_left") else -1.0
		
		steering_input = first_pressed_dir
		# Activate drift mode automatically when both are held
		_apply_movement(delta, true)
	else:
		# Reset tracking when one or both keys are released
		first_pressed_dir = 0.0
		steering_input = Input.get_axis("ui_left", "ui_right")
		_apply_movement(delta, false)

func _apply_movement(delta: float, is_drifting: bool) -> void:
	var current_speed = DRIFT_SPEED if is_drifting else BASE_SPEED 
	
	# 2. ACCUMULATE ROTATION
	var rotation_factor = DRIFT_STEERING_SENSITIVITY if is_drifting else BASE_STEERING_SENSITIVITY
	current_yaw -= steering_input * (turn_sensitivity * rotation_factor) * delta
	rotation.y = current_yaw
	
	# 3. CALCULATE DIRECTION
	var forward_vector = -transform.basis.z 
	velocity.x = forward_vector.x * current_speed
	
	# 4. VISUAL TILT (Subtle roll)
	var target_tilt = -steering_input * 0.1
	rotation.z = lerp_angle(rotation.z, target_tilt, 5.0 * delta)
	
	velocity.z = 0
	if is_drifting:
		print("drifting")
	else:
		print("\n")
	move_and_slide()
