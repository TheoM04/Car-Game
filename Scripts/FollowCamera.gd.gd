extends Camera3D

@export var lerp_speed = 3.0
@export var target: Node3D
@export var offset = Vector3(0, 2.5, 4.0) # Example offset: up 2.5, back 4

func _physics_process(delta):
	if !target:
		return

	# Calculate the target position in world space
	var target_pos = target.global_position + offset
	
	# Move the camera to that position
	global_position = global_position.lerp(target_pos, lerp_speed * delta)
	
	# Look at the car (slightly ahead (-2.0) to make it feel more dynamic)
	var look_target = target.global_position + Vector3(0, 0.5, -2.0)
	look_at(look_target, Vector3.UP)
