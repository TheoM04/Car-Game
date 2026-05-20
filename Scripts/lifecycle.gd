extends Node3D

enum State { TITLE, PLAY, GAMEOVER }

var state

@onready var music_player: AudioStreamPlayer = get_node("MusicPlayer")
@onready var title_layer: CanvasLayer = get_node("TitleLayer")
@onready var hud_layer: CanvasLayer = get_node("HUDLayer")
@onready var gameover_layer: CanvasLayer = get_node("GameOverLayer")
@onready var car: Node3D = get_node("Car")

var terrain_controllers: Array[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrain_controllers = get_tree().get_nodes_in_group("terrain_controller")
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
	car.set_physics_process(false)

	music_player.stop()

	title_layer.visible = true
	hud_layer.visible = false
	gameover_layer.visible = false

	state = State.TITLE

func play():
	for terrain in terrain_controllers:
		terrain.should_move = 1
		terrain.set_physics_process(true)

	title_layer.visible = false
	hud_layer.visible = true
	gameover_layer.visible = false

	music_player.change_song(0)
	music_player.play()

	car.set_process_unhandled_input(true)

	state = State.PLAY

func game_over():
	car.set_process_unhandled_input(false)

	for terrain in terrain_controllers:
		terrain.should_move = 0
		terrain.set_physics_process(false)

	hud_layer.visible = false
	gameover_layer.visible = true

	state = State.GAMEOVER
