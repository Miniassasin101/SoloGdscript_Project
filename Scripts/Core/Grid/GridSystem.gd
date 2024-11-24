# GridSystem.gd
# Manages the grid system for the game.

class_name GridSystem
extends Node

# Dimensions of the grid.
var width: int
var height: int

# Size of each cell in the grid.
var cell_size: float

# 2D array of GridObject instances.
var grid_object_array: Array = []

# Dictionary to store GridPosition instances.
var grid_positions = {}  

# Array to store references to all Label3D instances (for debugging).
var label_3d_list: Array = []

func _init(in_width: int, in_height: int, in_cell_size: float) -> void:
	# Initialize grid dimensions and cell size.
	width = in_width
	height = in_height
	cell_size = in_cell_size
	# Initialize the grid objects.
	initialize_grid_objects()

# Initializes and populates the grid with GridObject instances.
func initialize_grid_objects() -> void:
	for x in range(width):
		var row: Array = []
		grid_positions[x] = {}
		for z in range(height):
			# Create a new GridPosition for the current cell.
			var grid_position = GridPosition.new(x, z)
			# Add grid_position to the grid_positions dictionary
			grid_positions[x][z] = grid_position
			# Create a new GridObject for the current cell.
			var grid_object = GridObject.new(self, grid_position)
			# Add the GridObject to the current row.
			row.append(grid_object)
		# Add the row to the main grid array.
		grid_object_array.append(row)


# Creates debug labels at each grid cell (for visualization).
func create_debug_objects() -> void:
	# Clear previous labels.
	for row in label_3d_list:
		for label in row:
			if label:
				label.queue_free()
	label_3d_list.clear()

	# Create new labels for the current grid configuration.
	for x in range(width):
		label_3d_list.append([])  # Initialize label_3d_list[x] as an empty array.
		for z in range(height):
			# Get world position and grid object.
			var position = get_world_position(x, z)
			var grid_position = GridPosition.new(x, z)
			var grid_object = get_grid_object(grid_position)

			# Create the Label3D to display the grid coordinates.
			var label_3d = Label3D.new()
			label_3d.text = grid_object.to_str()  # Display grid coordinates as text.
			
			# Position the label slightly above the grid cell.
			label_3d.transform.origin = position + Vector3(0, 0.02, 0)
			
			# Rotate the label to face upwards.
			label_3d.rotate(Vector3(1, 0, 0), -PI / 2)
			
			# Add the label to the scene.
			add_child(label_3d)
			label_3d_list[x].append(label_3d)  # Store the label in the 2D array.


# Rotates all debug labels (for visualization purposes).
func rotate_labels(direction: float) -> void:
	for row in label_3d_list:
		for label in row:
			if label and label is Label3D:
				label.rotate(Vector3(0, 1, 0), direction * PI / 4)  # Rotate 45 degrees around the Y-axis.

# Updates the debug label at a specific grid position.
func update_debug_label(grid_position: GridPosition) -> void:
	if is_valid_grid_position(grid_position):
		var x = grid_position.x
		var z = grid_position.z
		var grid_object = get_grid_object(grid_position)
		label_3d_list[x][z].text = grid_object.to_str()


func update_walkability_from_bounding_boxes(bounding_boxes: Array) -> void:
	# Offset for height consideration (hovering slightly above the ground)
	var height_offset = Vector3(0, 0.6, 0)

	# Iterate over all grid positions
	for x in range(width):
		for z in range(height):
			var grid_position = grid_positions[x][z]
			var world_position = get_world_position(x, z) + height_offset

			# Check if this grid position is inside any of the bounding boxes
			var is_walkable = true
			for aabb: AABB in bounding_boxes:
				if aabb.has_point(world_position):
					is_walkable = false
					break
			
			# Update the grid object's walkability
			var grid_object = get_grid_object(grid_position)
			if grid_object:
				grid_object.is_walkable = is_walkable
	
	# Optionally, update visuals or AStar pathfinding here
	Pathfinding.instance.update_astar_walkable()
	



#getter/setter functions


# Converts grid coordinates to world position.
func get_world_position(x: int, z: int) -> Vector3:
	return Vector3(x * cell_size, 0, z * cell_size)

func get_world_position_from_grid_position(ingrid_position: GridPosition):
	return get_world_position(ingrid_position.x, ingrid_position.y)

# Converts world position to grid position.
func get_grid_position(world_position: Vector3) -> GridPosition:
	var x = roundi(world_position.x / cell_size)
	var z = roundi(world_position.z / cell_size)
	if is_valid_grid_coords(x, z):
		return grid_positions[x][z]
	else:
		return null  # Or handle invalid positions as needed

func get_grid_position_from_coords(x: int, z: int) -> GridPosition:
	if is_valid_grid_coords(x, z):
		return grid_positions[x][z]
	else:
		return null  # Or handle invalid positions as needed

func get_grid_position_from_grid_position(ingrid: GridPosition) -> GridPosition:
	if is_valid_grid_position(ingrid):
		return grid_positions[ingrid.x][ingrid.z]
	else:
		return ingrid

# Helper function to check if coordinates are within grid bounds.
func is_valid_grid_coords(x: int, z: int) -> bool:
	return x >= 0 and x < width and z >= 0 and z < height



# Retrieves the GridObject at the specified grid position.
func get_grid_object(grid_position: GridPosition) -> GridObject:
	if is_valid_grid_position(grid_position):
		return grid_object_array[grid_position.x][grid_position.z]
	else:
		return null

# Checks if a grid position is within the bounds of the grid.
func is_valid_grid_position(grid_position: GridPosition) -> bool:
	return is_valid_grid_coords(grid_position.x, grid_position.z)

func get_width() -> int:
	return width
	
func get_height() -> int:
	return height
