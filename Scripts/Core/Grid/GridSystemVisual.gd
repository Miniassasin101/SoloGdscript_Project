class_name GridSystemVisual
extends Node3D

# The prefab for each grid cell's visual representation.
const GRID_CELL_VISUAL: PackedScene = preload("res://Hero_Game/Prefabs/GridCellVisual.tscn")

# 2D array to hold the visual instances of grid cells.
var grid_visuals: Array = []  # Array of Arrays of Node3D instances.

var selected_action: Action
var selected_ability: Ability
# Singleton instance of GridSystemVisual.
static var instance: GridSystemVisual = null

func _ready() -> void:
	# Ensure only one instance exists (singleton pattern).
	if instance != null:
		push_error("There's more than one GridSystemVisual! " + str(transform) + " - " + str(instance))
		queue_free()
		return
	instance = self
	SignalBus.update_grid_visual.connect(update_grid_visual)
	initialize_grid_visuals()
	#update_grid_visual()

func initialize_grid_visuals() -> void:
	# Ensure LevelGrid singleton is properly loaded.
	if not LevelGrid:
		push_error("LevelGrid singleton not found.")
		return

	# Get grid dimensions from LevelGrid.
	var grid_width: int = LevelGrid.get_width()
	var grid_height: int = LevelGrid.get_height()

	# Initialize the 2D array to match the dimensions of LevelGrid.
	grid_visuals.resize(grid_width)

	# Loop through the width and height of the grid.
	for x in range(grid_width):
		grid_visuals[x] = []  # Initialize each row as an empty array.
		for z in range(grid_height):
			# Create a new GridPosition based on x and z.
			var grid_position: GridPosition = GridPosition.new(x, z)

			# Instantiate the visual prefab.
			var cell_instance: Node3D = GRID_CELL_VISUAL.instantiate()

			# Set the position of the cell in the world.
			cell_instance.transform.origin = LevelGrid.get_world_position(grid_position)

			# Add the instance as a child of this node.
			add_child(cell_instance)

			# Store the instance in the 2D array at position (x, z).
			grid_visuals[x].append(cell_instance)

func _process(_delta: float) -> void:
	pass

func hide_all_grid_positions() -> void:
	# Hide all grid cell visuals.
	for row in grid_visuals:
		for cell in row:
			cell.visible = false

func show_grid_positions(grid_positions: Array) -> void:
	# Show specified grid cell visuals.
	for grid_position in grid_positions:
		var x: int = grid_position.x
		var z: int = grid_position.z
		# Check if the position is within grid bounds.
		if x >= 0 and x < LevelGrid.get_width() and z >= 0 and z < LevelGrid.get_height():
			grid_visuals[x][z].visible = true

func update_grid_visual_pathfinding(grid_list: Array[GridPosition]):
	if !grid_list.is_empty():
		hide_all_grid_positions()
		show_grid_positions(grid_list)
		

func update_grid_visual() -> void:
	#if Input.is_action_just_pressed("testkey"):
	hide_all_grid_positions()

	selected_action = UnitActionSystem.instance.get_selected_action()
	if selected_action != null:
		show_grid_positions(selected_action.get_valid_action_grid_position_list())
	selected_ability = UnitActionSystem.instance.get_selected_ability()
	if selected_ability != null:
		if UnitActionSystem.instance.selected_unit != null:
			show_grid_positions(UnitActionSystem.instance
			.selected_unit.ability_container.get_valid_ability_target_grid_position_list(selected_ability)
			)
		
