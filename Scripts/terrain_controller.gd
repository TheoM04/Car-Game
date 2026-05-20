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

@export var render_distance = 80
## The number of blocks to keep rendered to the viewport
var num_of_blocks_to_spawn

## Path to directory holding the terrain block scenes
@export var terrian_blocks: Array[TerrainBlockData]
var block_size: float

var should_move = 1

@export var x_offset: float = 0
@export var y_offset: float = 0
@export var y_rotation: float = 0

#Enviroments
var enviroments = {}

func _ready() -> void:
	_load_terrain_scenes(terrian_blocks)
	
	num_of_blocks_to_spawn = ceil(render_distance / block_size)
	print("\n\n---------------"+name+"---------------\n")
	print("	render distance: %.2f\n	block size: %.2f\n	num_of_blocks_to_spawn: %.2f\n"%[render_distance,block_size,num_of_blocks_to_spawn])
	
	_init_blocks(num_of_blocks_to_spawn)
	
	should_move = 1
	print("\n	enviroments:")
	for key in enviroments:
		print("		",key.split("/")[-1] + ": ", len(enviroments[key]))

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)

func _load_terrain_scenes(target_blocks: Array[TerrainBlockData]) -> void:
	for block in target_blocks:
		block_size = block.block_size
		var path: String = block.path
		var dir = DirAccess.open(path)
		if not dir:
			print("Error: Could not open directory: ", path)
			continue
		
		enviroments[path] = []
		for file_name in dir.get_files():
			var scene_path: String = file_name
			
			# Handle remapped files in exported builds
			if scene_path.ends_with(".remap"):
				scene_path = scene_path.trim_suffix(".remap")
			
			# Only load valid scene extensions
			if scene_path.ends_with(".scn") or scene_path.ends_with(".tscn"):
				var full_path = path + "/" + scene_path
				print("    Loading terrain block scene: ", full_path)
				
				TerrainBlocks.append(load(full_path))
				enviroments[path].append(scene_path)

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
	terrain_belt[0].position.z += terrain_velocity  * should_move * delta
	
	for i in range(1, terrain_belt.size()):
		terrain_belt[i].position.z = terrain_belt[i-1].position.z - block_size

	if terrain_belt[0].position.z >= block_size*3/2:
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
