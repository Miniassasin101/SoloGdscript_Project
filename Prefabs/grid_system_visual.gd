class_name GridSystemVisual
extends Node3D

# The prefab for each grid cell's visual representation
const GRID_CELL_VISUAL = preload("res://Hero_Game/Prefabs/GridCellVisual.tscn")
var grid_cell_visual_prefab: PackedScene

# Reference to the LevelGrid node
@onready var level_grid: LevelGrid = get_node("/root/LevelGrid")  # Adjust the path as needed

func _ready() -> void:
	grid_cell_visual_prefab = GRID_CELL_VISUAL

	# Ensure LevelGrid is properly referenced
	if not level_grid:
		push_error("LevelGrid node not found. Check the node path.")
		return

	# Loop through the width and height of the grid
	for x in range(level_grid.get_width()):
		for z in range(level_grid.get_height()):
			# Create a new GridPosition based on x and z
			var grid_position = GridPosition.new(x, z)

			# Instantiate the visual prefab
			var instance = grid_cell_visual_prefab.instantiate()

			# Set the local transform origin before adding to the scene tree
			instance.transform.origin = level_grid.get_world_position(grid_position)

			# Now add the instance as a child of this node
			add_child(instance)
