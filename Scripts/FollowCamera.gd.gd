extends Camera3D

@export var target_node : Node3D
@export var terrain_controller : Node3D
@export var follow_speed : float = 4.0 # How fast the camera catches up
@export var rotation_speed : float = 2.0 # How fast the camera turns its "head"

var offset : Vector3

func _ready():

	if target_node:
		offset = global_position - target_node.global_position

func _physics_process(delta):
	if not target_node:
		return

	var speed_percent = terrain_controller.active_speed / terrain_controller.max_speed
	fov = lerp(75.0, 85.0, speed_percent * delta)

	# 1. Smoothly follow the car's X position
	var target_pos = target_node.global_position + offset
	global_position.x = lerp(global_position.x, target_pos.x, follow_speed * delta)
	
	# 2. Look "Into" the turn
	var look_at_pos = target_node.global_position + Vector3(0, 0.5, -2)
	
	var original_rot = rotation.y
	look_at(look_at_pos)
	var target_rot = rotation.y
	
	rotation.y = lerp_angle(original_rot, target_rot, rotation_speed * delta)
