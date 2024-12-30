# LevelGrid.gd
# Autoloaded singleton
extends Node

# Reference to the GridSystem instance
var grid_system: GridSystem


# Initialization
func _init() -> void:
	pass
	# Create a new GridSystem with specified dimensions and cell size
	#grid_system = GridSystem.new(10, 10, 2.0)
	
	# Add the grid system as a child of the current node
	#add_child(grid_system)
	# Create debug objects for visualizing the grid
	#grid_system.create_debug_objects()

func generate_grid_system(x: int, z: int, grid_scale: float):
		# Create a new GridSystem with specified dimensions and cell size
	grid_system = GridSystem.new(x, z, grid_scale)
	
	# Add the grid system as a child of the current node
	add_child(grid_system)
	# Create debug objects for visualizing the grid
	grid_system.create_debug_objects()
	
# Called every frame
func _process(_delta: float) -> void:
	# Rotate labels 45 degrees clockwise
	if Input.is_action_just_pressed("rotate_right"):
		grid_system.rotate_labels(1)  # Pass 1 for clockwise rotation

	# Rotate labels 45 degrees counterclockwise
	if Input.is_action_just_pressed("rotate_left"):
		grid_system.rotate_labels(-1)  # Pass -1 for counterclockwise rotation

# Assigns a unit to a specified grid position
func set_unit_at_grid_position(grid_position: GridPosition, unit: Unit) -> void:
	var grid_object: GridObject = grid_system.get_grid_object(grid_position)
	if grid_object != null:
		grid_object.add_unit(unit)
		# Update only the affected label
		grid_system.update_debug_label(grid_position)

# Retrieves the list of units at a specified grid position
func get_unit_list_at_grid_position(grid_position: GridPosition) -> Array:
	var grid_object: GridObject = grid_system.get_grid_object(grid_position)
	return grid_object.get_unit_list()

# Removes a unit from a specified grid position
func remove_unit_at_grid_position(grid_position: GridPosition, unit: Unit) -> void:
	var grid_object: GridObject = grid_system.get_grid_object(grid_position)
	if grid_object != null:
		grid_object.remove_unit(unit)
		grid_system.update_debug_label(grid_position)

# Handles moving a unit from one grid position to another
func unit_moved_grid_position(unit: Unit, from_grid_position: GridPosition, to_grid_position: GridPosition) -> void:
	remove_unit_at_grid_position(from_grid_position, unit)
	set_unit_at_grid_position(to_grid_position, unit)

# Converts a world position to a grid position
func get_grid_position(world_position: Vector3) -> GridPosition:
	return grid_system.get_grid_position(world_position)

# Converts a grid position to a world position
func get_world_position(grid_position: GridPosition) -> Vector3:
	return grid_system.get_world_position(grid_position.x, grid_position.z)

func get_width() -> int:
	return grid_system.width

func get_height() -> int:
	return grid_system.height


# Checks if a grid position is valid within the grid system
func is_valid_grid_position(grid_position: GridPosition) -> bool:
	return grid_system.is_valid_grid_position(grid_position)

# Checks if any unit is present at a specified grid position
func has_any_unit_on_grid_position(grid_position: GridPosition) -> bool:
	var grid_object = grid_system.get_grid_object(grid_position)
	return grid_object.has_any_unit()

func get_unit_at_grid_position(grid_position: GridPosition):
	var grid_object: GridObject = grid_system.get_grid_object(grid_position)
	if grid_object:
		return grid_object.get_unit()
	return null
