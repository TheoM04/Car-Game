extends CharacterBody3D

const BASE_SPEED = 5.0
const DRIFT_SPEED = 6.0

const BASE_STEERING_SENSITIVITY = 1.0
const DRIFT_STEERING_SENSITIVITY = 0.75

const OBSTACLE_HEAVY_CRASH_DISTANCE = 0.4
const SCRAPE_DAMAGE = 25
const STUCK_DAMAGE = 40

var steering_input = 0.0
var current_yaw = 0.0 
var has_crashed := false

# Health Variables
@export var max_health: float = 100.0
var current_health: float = max_health

@export var turn_sensitivity = 2.0

@onready var car_mesh: Node3D = $CarMesh
@onready var left_smoke: GPUParticles3D = $LeftSmoke
@onready var right_smoke: GPUParticles3D = $RightSmoke

# Logic for tracking the first pressed key for drifting
var first_pressed_dir = 0.0

# Track currently overlapping obstacles for continuous damage
var scraping_obstacles: Array[Node3D] = []
var damage_tick_timer = 0.0
const TICK_RATE = 0.4 # Apply side damage every TICK_RATE seconds while stuck

func _ready() -> void:
	# Connect both entered and exited signals to manage getting stuck/unstuck
	$CrashDetector.body_entered.connect(_on_crash_detector_body_entered)
	$CrashDetector.body_exited.connect(_on_crash_detector_body_exited)

func _physics_process(delta: float) -> void:
	if has_crashed:
		if Input.is_action_just_pressed("ui_select"):
			get_tree().reload_current_scene()
		return
		
	# Handle continuous damage if stuck against an obstacle
	if not scraping_obstacles.is_empty():
		damage_tick_timer += delta
		if damage_tick_timer >= TICK_RATE:
			damage_tick_timer = 0.0
			_apply_damage(STUCK_DAMAGE, "⚡ STUCK! Continuous scraping damage...")

	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	
	if left and right:
		if first_pressed_dir == 0.0:
			first_pressed_dir = 1.0 if Input.is_action_just_pressed("ui_left") else -1.0
		
		steering_input = first_pressed_dir
		_apply_movement(delta, true)
	else:
		first_pressed_dir = 0.0
		steering_input = Input.get_axis("ui_left", "ui_right")
		_apply_movement(delta, false)

func _update_particles(is_drifting: bool) -> void:
	if left_smoke and right_smoke:
		var emitting = !has_crashed && (is_drifting || steering_input != 0.0)
		left_smoke.emitting = emitting
		right_smoke.emitting = emitting

func _apply_movement(delta: float, is_drifting: bool) -> void:
	var current_speed = DRIFT_SPEED if is_drifting else BASE_SPEED 
	
	var rotation_factor = DRIFT_STEERING_SENSITIVITY if is_drifting else BASE_STEERING_SENSITIVITY
	current_yaw -= steering_input * (turn_sensitivity * rotation_factor) * delta
	rotation.y = current_yaw
	
	var forward_vector = -transform.basis.z 
	velocity.x = forward_vector.x * current_speed
	
	# Visual tilt
	var target_tilt = -steering_input * 0.1
	rotation.z = lerp_angle(rotation.z, target_tilt, 5.0 * delta)
	
	_update_particles(true)
	
	velocity.z = 0
	velocity.y = 0
	move_and_slide()

func _on_crash_detector_body_entered(body: Node3D) -> void:
	if has_crashed: 
		return
		
	if body.is_in_group("obstacle"):
		var local_pos = global_transform.inverse() * body.global_position
		var distance_from_center = abs(local_pos.x)
		
		# 1. HUGE DAMAGE -> Instant Wreck
		if distance_from_center < OBSTACLE_HEAVY_CRASH_DISTANCE:
			_apply_damage(max_health, "💥 DIRECT HEAD-ON COLLISION!")
		# 2. LIGHT DAMAGE -> Track for continuous scrape damage
		else:
			if not scraping_obstacles.has(body):
				scraping_obstacles.append(body)
			_apply_damage(SCRAPE_DAMAGE, "🚗 INITIAL CLIP! Side Scrape!")

func _on_crash_detector_body_exited(body: Node3D) -> void:
	# If we successfully steer away and clear the obstacle, remove it from our tracking
	if scraping_obstacles.has(body):
		scraping_obstacles.erase(body)
		damage_tick_timer = 0.0 # Reset tick timer

func _apply_damage(amount: float, message: String) -> void:
	current_health -= amount
	print(message, "\nCurrent Health: ", current_health if current_health > 0 else 0, "/", max_health)
	
	if current_health <= 0:
		trigger_game_over()

func trigger_game_over() -> void:
	if has_crashed: return
	has_crashed = true
	velocity = Vector3.ZERO
	scraping_obstacles.clear()
	_update_particles(false)
	
	var terrain = get_tree().get_first_node_in_group("terrain_controller")
	if terrain:
		terrain.active_speed = 0.0
		terrain.set_physics_process(false)
	
	print("💀 TOTALED! Game Over. Press Spacebar to Restart.")
