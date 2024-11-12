class_name LevelGrid
extends Node

var grid_system: GridSystem

@onready var mouse_world: MouseWorld = $"../MouseWorld"

func _init() -> void:
	grid_system = GridSystem.new(10, 10, 2.0)
	
	# Add the grid system as a child of the current node
	add_child(grid_system)
	grid_system.create_debug_objects()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Check if the left mouse button was just pressed
	if Input.is_action_just_pressed("left_mouse"):
		# Get the mouse's world position using the viewport's camera
		var mouse_position = mouse_world.get_mouse_position()["position"]
		
		# Get the grid position corresponding to the mouse position
		var grid_position = grid_system.get_grid_position(mouse_position)
		
		# Print the grid position for debugging purposes
		print_debug(grid_position.to_str())
	

	
	# Rotate labels 45 degrees clockwise
	if Input.is_action_just_pressed("rotate_right"):
		grid_system.rotate_labels(1)  # Pass 1 for clockwise rotation

	# Rotate labels 45 degrees counterclockwise
	if Input.is_action_just_pressed("rotate_left"):
		grid_system.rotate_labels(-1)  # Pass -1 for counterclockwise rotation
	


func set_unit_at_grid_position(gridPosition: GridPosition, unit: Unit) -> void:
	var gridObject: GridObject = grid_system.get_grid_object(gridPosition)
	if gridObject != null:
		gridObject.add_unit(unit)
		grid_system.create_debug_objects()

	
func get_unit_list_at_grid_position(gridPosition: GridPosition) -> Unit:
	var gridObject: GridObject = grid_system.get_grid_object(gridPosition)
	return gridObject.get_unit_list()
	
func remove_unit_at_grid_position(gridPosition: GridPosition, unit: Unit) -> void:
	var gridObject: GridObject = grid_system.get_grid_object(gridPosition)
	if gridObject != null:
		gridObject.remove_unit(unit)

func unit_moved_grid_position(unit: Unit, fromGridPosition: GridPosition, toGridPosition: GridPosition) -> void:
	remove_unit_at_grid_position(fromGridPosition, unit)
	
	set_unit_at_grid_position(toGridPosition, unit)
	



func get_grid_position(worldPosition: Vector3) -> GridPosition:
	return grid_system.get_grid_position(worldPosition)

func get_world_position(world_position: GridPosition) -> Vector3:
	return grid_system.get_world_position(world_position.x, world_position.z)

func is_valid_grid_position(grid_position: GridPosition) -> bool:
	return grid_system.is_valid_grid_position(grid_position)
 
func has_any_unit_on_grid_position(grid_position: GridPosition) -> bool:
	var grid_object = grid_system.get_grid_object(grid_position)
	return grid_object.has_any_unit()

	
