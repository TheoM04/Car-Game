extends Node3D

enum State { TITLE, PLAY, GAMEOVER }

var state

@export var environments: Array[Env]

@onready var title_layer: CanvasLayer = get_node("TitleLayer")

@onready var hud_layer: CanvasLayer = get_node("HUDLayer")
@onready var points_label = get_node("HUDLayer/PointsLabel")

@onready var gameover_layer: CanvasLayer = get_node("GameOverLayer")
@onready var restart_label = get_node("GameOverLayer/RestartPrompt")

@onready var car: Node3D = get_node("Car")

@onready var road_controller: TerrainController = get_node("RoadController")
@onready var left_decor_controller: TerrainController = get_node("LeftDecorationController")
@onready var right_decor_controller: TerrainController = get_node("RightDecorationController")
@onready var obstacle_placer: TerrainController = get_node("ObstaclePlacer")
var terrain_controllers: Array[Node]

@onready var music_player: MusicPlayer = get_node("MusicPlayer")

var last_beat_ts: int
var pending_close_call_ts: int
var points = 0:
	set(new):
		points_label.set_points(new)
		points = new

func apply_env(env: Env):
	road_controller.terrain_blocks = [env.road.blocks]
	road_controller.load_terrain_scenes()
	
	left_decor_controller.terrain_blocks = [env.decor.blocks]
	left_decor_controller.x_offsets.assign(env.decor.x_offsets.map(func (x): return -x))
	left_decor_controller.y_offsets = env.decor.y_offsets
	left_decor_controller.y_rotations.assign(env.decor.y_rotations.map(func (d): return -d))
	left_decor_controller.load_terrain_scenes()
	
	right_decor_controller.terrain_blocks = [env.decor.blocks]
	right_decor_controller.x_offsets = env.decor.x_offsets
	right_decor_controller.y_offsets = env.decor.y_offsets
	right_decor_controller.y_rotations = env.decor.y_rotations
	right_decor_controller.load_terrain_scenes()
	
	obstacle_placer.terrain_blocks = [env.obstacles.blocks]
	obstacle_placer.x_offsets = env.obstacles.x_offsets
	obstacle_placer.y_offsets = env.obstacles.y_offsets
	obstacle_placer.y_rotations = env.obstacles.y_rotations
	obstacle_placer.place_chance = env.obstacles.chance
	obstacle_placer.load_terrain_scenes()

	music_player.change_song(env.song, env.bpm)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrain_controllers = get_tree().get_nodes_in_group("terrain_controller")
	apply_env(environments.pick_random())
	title()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	match state:
		State.TITLE:
			pass
		State.PLAY:
			pass
		State.GAMEOVER:
			pass
		_:
			printerr("Invalid state")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and state != State.PLAY:
		if state == State.GAMEOVER:
			car.reset()
		play()

func title():
	car.set_process_unhandled_input(false)

	music_player.stop()

	obstacle_placer.should_generate = false

	title_layer.visible = true
	hud_layer.visible = false
	gameover_layer.visible = false

	state = State.TITLE

func play():
	points = 0

	for terrain in terrain_controllers:
		terrain.should_move = true
		terrain.set_physics_process(true)

	obstacle_placer.clear()
	obstacle_placer.should_generate = false
	
	title_layer.visible = false
	hud_layer.visible = true
	gameover_layer.visible = false

	music_player.restart()

	car.set_process_unhandled_input(true)

	state = State.PLAY

func game_over():
	car.set_process_unhandled_input(false)

	for terrain in terrain_controllers:
		terrain.should_move = false
		terrain.set_physics_process(false)

	restart_label.set_points(points)

	hud_layer.visible = false
	gameover_layer.visible = true

	state = State.GAMEOVER

func _on_music_player_finished() -> void:
	apply_env(environments.pick_random())
	music_player.restart()

func _on_music_player_beat(n: int) -> void:
	if n == 1 and state == State.PLAY:
		obstacle_placer.should_generate = true

	if car.near:
		points += 1
