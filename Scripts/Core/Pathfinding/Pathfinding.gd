class_name Pathfinding
extends Node

var width: int
var height: int
var cell_size: float
var pathfinding_grid_system: GridSystem

var astar: CustomAStar3D

static var instance: Pathfinding = null



func _ready() -> void:
	if instance != null:
		push_error("There's more than one UnitActionSystem! - " + str(instance))
		queue_free()
		return
	instance = self
	# Create a new GridSystem and initialize CustomAStar3D
	pathfinding_grid_system = LevelGrid.grid_system # GridSystem.new(10, 10, 2.0)
	astar = CustomAStar3D.new()
	setup_astar()

# Function to find the path between two grid positions.
func find_path(start_grid_position: GridPosition, end_grid_position: GridPosition) -> Array[GridPosition]:
	# Get the point IDs in AStar3D for the start and end positions.
	var start_id = astar.get_closest_point(pathfinding_grid_system.get_world_position(start_grid_position.x, start_grid_position.z))
	var end_id = astar.get_closest_point(pathfinding_grid_system.get_world_position(end_grid_position.x, end_grid_position.z))
	
	# Initialize an empty array for the path.
	var grid_path: Array[GridPosition] = []

	if start_id != -1 and end_id != -1:
		# Get the path of point IDs from AStar3D.
		var id_path = astar.get_id_path(start_id, end_id, false)

		# Convert the point IDs to GridPosition instances and add them to the path array.
		for point_id in id_path:
			var point_position = astar.get_point_position(point_id)
			var grid_position = pathfinding_grid_system.get_grid_position(point_position)
			if grid_position != null:
				grid_path.append(grid_position)

	return grid_path

# Function to set up the AStar3D grid.
func setup_astar() -> void:
	var id: int = 0
	# Add points to the AStar3D instance, each representing a grid cell.
	for x in range(pathfinding_grid_system.get_width()):
		for z in range(pathfinding_grid_system.get_height()):
			if pathfinding_grid_system.is_valid_grid_coords(x, z):
				var vector_point: Vector3 = pathfinding_grid_system.get_world_position(x, z)
				
				# Add point only if it doesn't already exist
				if not astar.has_point(id):
					astar.add_point(id, vector_point)

				# Connect current point with its neighbors if applicable and valid
				# Horizontal and Vertical Neighbors
				if x > 0 and astar.has_point(id - pathfinding_grid_system.get_height()):
					astar.connect_points(id, id - pathfinding_grid_system.get_height(), true)  # Connect left neighbor
				if z > 0 and astar.has_point(id - 1):
					astar.connect_points(id, id - 1, true)  # Connect top neighbor

				# Diagonal Neighbors
				if x > 0 and z > 0 and astar.has_point(id - pathfinding_grid_system.get_height() - 1):
					astar.connect_points(id, id - pathfinding_grid_system.get_height() - 1, true)  # Connect top-left neighbor
				if x > 0 and z < pathfinding_grid_system.get_height() - 1 and astar.has_point(id - pathfinding_grid_system.get_height() + 1):
					astar.connect_points(id, id - pathfinding_grid_system.get_height() + 1, true)  # Connect bottom-left neighbor
				if x < pathfinding_grid_system.get_width() - 1 and z > 0 and astar.has_point(id + pathfinding_grid_system.get_height() - 1):
					astar.connect_points(id, id + pathfinding_grid_system.get_height() - 1, true)  # Connect top-right neighbor
				if x < pathfinding_grid_system.get_width() - 1 and z < pathfinding_grid_system.get_height() - 1 and astar.has_point(id + pathfinding_grid_system.get_height() + 1):
					astar.connect_points(id, id + pathfinding_grid_system.get_height() + 1, true)  # Connect bottom-right neighbor

				id += 1


# Helper Functions

# Adds a point to the AStar3D instance at the given grid position.
func add_point_to_astar(grid_position: GridPosition, weight_scale: float = 1.0) -> void:
	var vector_point: Vector3 = pathfinding_grid_system.get_world_position_from_grid_position(grid_position)
	var point_id = get_grid_point_id(grid_position)
	if not astar.has_point(point_id):
		astar.add_point(point_id, vector_point, weight_scale)

# Connects two points if both points exist in AStar3D.
func connect_points_if_valid(id1: int, id2: int, bidirectional: bool = true) -> void:
	if astar.has_point(id1) and astar.has_point(id2):
		astar.connect_points(id1, id2, bidirectional)

# Generates a unique point ID for each grid position.
func get_grid_point_id(grid_position: GridPosition) -> int:
	return grid_position.x * pathfinding_grid_system.get_height() + grid_position.z

# Finds all valid neighbors of a given grid position.
func find_neighbors(grid_position: GridPosition) -> Array[GridPosition]:
	var neighbors: Array[GridPosition] = []
	var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for direction in directions:
		var new_pos = GridPosition.new(grid_position.x + direction.x, grid_position.z + direction.y)
		if pathfinding_grid_system.is_valid_grid_position(new_pos):
			new_pos = pathfinding_grid_system.get_grid_position_from_grid_position(new_pos)
			neighbors.append(new_pos)
	return neighbors

# Clears all points and segments from AStar3D.
func clear_astar() -> void:
	astar.clear()

# Checks if a point is within a certain movement range.
func is_point_in_range(start_grid_position: GridPosition, end_grid_position: GridPosition, max_distance: float) -> bool:
	var start_id = get_grid_point_id(start_grid_position)
	var end_id = get_grid_point_id(end_grid_position)
	var path = astar.get_id_path(start_id, end_id)
	return astar.get_point_path_length(start_id, end_id) <= max_distance

#Note: Should also add a way later to just update a single point by passing in a single position or gridobject
func update_astar_walkable() -> void:
	# Iterate through all grid positions in the grid system
	for x in range(pathfinding_grid_system.get_width()):
		for z in range(pathfinding_grid_system.get_height()):
			# Get the current grid position
			var grid_position = pathfinding_grid_system.get_grid_position_from_coords(x, z)
			if grid_position:
				# Get the grid object at the position
				var grid_object = pathfinding_grid_system.get_grid_object(grid_position)
				if grid_object:
					# Check the is_walkable property
					var point_id = get_grid_point_id(grid_position)
					if grid_object.is_walkable:
						# Enable the point if it's walkable
						if astar.has_point(point_id):
							astar.set_point_disabled(point_id, false)
					else:
						# Disable the point if it's not walkable
						if astar.has_point(point_id):
							astar.set_point_disabled(point_id, true)

func is_walkable(grid_position: GridPosition) -> bool:
	return pathfinding_grid_system.get_grid_object(grid_position).is_walkable

# Disables a point in AStar3D to make it non-traversable.
func disable_point(grid_position: GridPosition) -> void:
	var point_id = get_grid_point_id(grid_position)
	if astar.has_point(point_id):
		astar.set_point_disabled(point_id, true)

# Enables a point in AStar3D to make it traversable again.
func enable_point(grid_position: GridPosition) -> void:
	var point_id = get_grid_point_id(grid_position)
	if astar.has_point(point_id):
		astar.set_point_disabled(point_id, false)

# Returns the total cost of the path between two points.
func get_path_cost(start_grid_position: GridPosition, end_grid_position: GridPosition) -> float:
	var start_id = get_grid_point_id(start_grid_position)
	var end_id = get_grid_point_id(end_grid_position)
	if start_id != -1 and end_id != -1:
		var id_path = astar.get_id_path(start_id, end_id)
		var total_cost: float = 0.0
		for i in range(id_path.size() - 1):
			total_cost += astar._compute_cost(id_path[i], id_path[i + 1])
		return total_cost
	return INF

# Checks if a path between two grid positions is available.
func is_path_available(start_grid_position: GridPosition, end_grid_position: GridPosition) -> bool:
	if find_path(start_grid_position, end_grid_position).size() > 0:
		return true
	else:
		return false


# Custom AStar3D Class to Override Cost Calculation
class CustomAStar3D extends AStar3D:
	# Override the compute cost function to handle diagonal cost
	func _compute_cost(from_id: int, to_id: int) -> float:
		var from_pos: Vector3 = get_point_position(from_id)
		var to_pos: Vector3 = get_point_position(to_id)
		var diff = to_pos - from_pos
		# Check if the movement is diagonal
		if abs(diff.x) > 0 and abs(diff.z) > 0:
			return 1.41  # Diagonal movement cost
		return 1.0  # Horizontal or vertical movement cost
