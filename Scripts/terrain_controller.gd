extends Node3D
class_name TerrainController
## This builds and operates the terrain "conveyor belt"
##
## A set of randomly choosen terrain blocks is rendered to the viewport.
## As the game played the terrian is moved in the postive Z direction.
## When a given block passes behind this node it is removed and a new block
## is added to the far end of the conveyor

## Holds the catalog of loaded terrian block scenes
var TerrainBlocks: Array = []
## The set of terrian blocks which are currently rendered to viewport
var terrain_belt: Array[AnimatableBody3D] = []
@export var terrain_velocity: float = 10.0
@export var max_speed: float = 20
@export var boost_multiplier: float = 2.0
@export var active_speed: float = 0.0
## The number of blocks to keep rendered to the viewport
@export var num_terrain_blocks = 4
## Path to directory holding the terrain block scenes
@export_dir var terrian_blocks_path = "res://Scenes/terrain_blocks"
@export var block_size: float = 17.277

@export var x_offset: float = 0
@export var y_offset: float = 0
@export var y_rotation: float = 0

func _ready() -> void:
	_load_terrain_scenes(terrian_blocks_path)
	_init_blocks(num_terrain_blocks)

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)

func _load_terrain_scenes(target_path: String) -> void:
	var dir = DirAccess.open(target_path)
	for scene_path in dir.get_files():
		print("Loading terrian block scene: " + target_path + "/" + scene_path)
		TerrainBlocks.append(load(target_path + "/" + scene_path))

func _init_blocks(number_of_blocks: int) -> void:
	for block_index in number_of_blocks:
		var block = TerrainBlocks.pick_random().instantiate()
		if block_index == 0:
			block.position.z = block_size/2
		else:
			_append_to_far_edge(terrain_belt[block_index-1], block)
		add_child(block)
		terrain_belt.append(block)


func _progress_terrain(delta: float) -> void:
	#var throttle = Input.get_action_strength("ui_up")
	#active_speed = terrain_velocity + (throttle * terrain_velocity * boost_multiplier)
	#if active_speed > max_speed: active_speed = max_speed

	#terrain_belt[0].position.z += active_speed * delta
	terrain_belt[0].position.z += terrain_velocity  * delta
	
	for i in range(1, terrain_belt.size()):
		terrain_belt[i].position.z = terrain_belt[i-1].position.z - block_size

	if terrain_belt[0].position.z >= block_size:
		var last_terrain = terrain_belt[-1]
		var first_terrain = terrain_belt.pop_front()
		
		var block = TerrainBlocks.pick_random().instantiate()
		_append_to_far_edge(last_terrain, block)
		add_child(block)
		terrain_belt.append(block)
		first_terrain.queue_free()


func _append_to_far_edge(target_block: AnimatableBody3D, appending_block: AnimatableBody3D) -> void:
	appending_block.position.z = target_block.position.z - block_size
	appending_block.position.x = x_offset
	appending_block.position.y = y_offset
	appending_block.rotation.y = y_rotation
