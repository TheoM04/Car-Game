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

## Path to directory holding the terrain block scenes
@export var terrain_blocks: Array[TerrainBlockData]
var block_size: float

var should_move = true
@export var should_generate = true

@export var x_offsets: Array[float] = [0]
@export var y_offsets: Array[float] = [0]
@export var y_rotations: Array[float] = [0]
@export var place_chance: float = 1

func _ready() -> void:
	load_terrain_scenes()

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)

func load_terrain_scenes() -> void:
	TerrainBlocks.clear()

	for block in terrain_blocks:
		block_size = block.block_size
		var path: String = block.path
		var dir = DirAccess.open(path)
		if not dir:
			print("Error: Could not open directory: ", path)
			continue

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

func _pick_block():
	if should_generate and randf() < place_chance:
		return TerrainBlocks.pick_random().instantiate()
	else:
		return AnimatableBody3D.new()

func _fill_to_edge():
	var prev_block = null if terrain_belt.is_empty() else terrain_belt[-1]

	while terrain_belt.is_empty() or terrain_belt[-1].position.z > -render_distance:
		var block = _pick_block()

		if terrain_belt.is_empty():
			block.position.z = block_size/2
		else:
			_append_to_far_edge(prev_block, block)

		add_child(block)
		terrain_belt.append(block)

		prev_block = block

func _progress_terrain(delta: float) -> void:
	for block in terrain_belt:
		block.position.z += terrain_velocity * int(should_move) * delta
	
	_fill_to_edge()
	
	if terrain_belt.is_empty():
		return
	elif terrain_belt[0].position.z >= block_size*3/2:
		terrain_belt.pop_front().queue_free()


func _append_to_far_edge(target_block: AnimatableBody3D, appending_block: AnimatableBody3D) -> void:
	appending_block.position.z = target_block.position.z - block_size
	appending_block.position.x = x_offsets.pick_random()
	appending_block.position.y = y_offsets.pick_random()
	appending_block.rotation.y = y_rotations.pick_random()

func clear():
	for block in terrain_belt:
		block.free()
	terrain_belt.clear()
