class_name GridSystem
extends Node

var width: int
var height: int
var cell_size: float
var gridObjectArray: Array = []
# Array to store references to all Label3D instances
var label_3d_list: Array = []

func _init(inwidth: int, inheight: int, incellsize: float) -> void:
	width = inwidth
	height = inheight
	cell_size = incellsize
	
	initialize_grid_objects()




# Initialize and populate the 2D grid with `GridObject` instances
func initialize_grid_objects() -> void:
	for x in range(width):
		var row: Array = []
		for z in range(height):
			# Create a new GridPosition for the current cell
			var grid_position = GridPosition.new(x, z)
			
			# Create a new GridObject for the current cell, passing in the GridSystem and GridPosition
			var grid_object = GridObject.new(self, grid_position)
		
			
			# Add the GridObject instance to the current row
			row.append(grid_object)
		# Add the row to the main 2D array
		gridObjectArray.append(row)
	#Example below
	#var grid_object = grid_system.gridObjectArray[x][z]
	
	
func get_world_position(x: int, z: int) -> Vector3:
	return Vector3(x * cell_size, 0, z * cell_size)

func get_grid_position(world_position: Vector3) -> GridPosition:
	return GridPosition.new(roundi(world_position.x / cell_size), roundi(world_position.z / cell_size))

func spawn_sphere_at_position(position: Vector3):
	var sphere_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_instance.mesh = sphere_mesh
	sphere_instance.transform.origin = position

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color for visibility
	sphere_instance.material_override = material

	add_child(sphere_instance)

func create_debug_objects() -> void:
	# Clear previous labels
	for label in label_3d_list:
		if label:  # Check if the label still exists
			label.queue_free()  # Free the label from memory
	label_3d_list.clear()  # Clear the list after freeing the labels

	# Create new labels for the current grid configuration
	for x in range(width):
		for z in range(height):
			# Calculate the world position for the current grid cell
			var position = get_world_position(x, z)
			var grid_position = get_grid_position(position)
			var grid_object = get_grid_object(grid_position)

			# Create the Label3D to display the grid coordinates
			var label_3d = Label3D.new()
			label_3d.text = grid_object.to_str()  # Display grid coordinates as text
			
			# Position the label above the grid cell
			label_3d.transform.origin = position + Vector3(0, 0.02, 0)
			
			# Rotate the label to face straight up (rotate -90 degrees around the X-axis)
			label_3d.rotate(Vector3(1, 0, 0), -PI / 2)
			
			# Add the label to the scene
			add_child(label_3d)
			label_3d_list.append(label_3d)  # Store the label for later access

func rotate_labels(direction: float) -> void:
	for label in label_3d_list:
		label.rotate(Vector3(0, 1, 0), direction * PI / 4)  # Rotate 45 degrees (PI / 4) around the Y-axis

func get_grid_object(grid_position: GridPosition) -> GridObject:
	if grid_position.x >= 0 and grid_position.x < width and grid_position.z >= 0 and grid_position.z < height:
		return gridObjectArray[grid_position.x][grid_position.z]
	else:
		#print("Grid position out of bounds: ", grid_position.to_str())
		return null

func is_valid_grid_position(grid_position: GridPosition) -> bool:
	return (grid_position.x >= 0 &&
			grid_position.z >= 0 &&
			grid_position.x < width &&
			grid_position.z < height)
