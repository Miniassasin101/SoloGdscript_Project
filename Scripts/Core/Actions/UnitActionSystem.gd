class_name UnitActionSystem
extends Node

# Reference to the currently selected unit
@export var selected_unit: Unit

# Reference to the LevelGrid node
@onready var level_grid: LevelGrid = LevelGrid

# Reference to the MouseWorld instance (set in the editor)
@export var mouse_world: MouseWorld

# Reference to the RayCast3D node (set in the editor)
@export var raycast: RayCast3D

# Self-reference for signal emission
@onready var unit_action_system: UnitActionSystem = self

# Reference to the active Camera3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()

# Layer mask for units
const UNIT_LAYER_MASK: int = 1 << 3

# Called every frame
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left_mouse"):
		# Attempt to select a unit
		if try_handle_unit_selection():
			return

		# Get the mouse position in the world
		var mouse_result = mouse_world.get_mouse_position()
		if mouse_result != null:
			var mouse_grid_position = LevelGrid.get_grid_position(mouse_result["position"])
			if selected_unit and mouse_grid_position != null:
				# Check if the grid position is valid for movement
				if selected_unit.get_move_action().is_valid_action_grid_position(mouse_grid_position):
					selected_unit.get_move_action().move(mouse_grid_position)
		else:
			print("No collision detected at mouse position.")

# Handles unit selection via mouse click
func try_handle_unit_selection() -> bool:
	# Get the mouse position in screen coordinates
	var mouse_position: Vector2 = get_viewport().get_mouse_position()

	# Perform raycast to detect units
	var result = get_mouse_position(camera, mouse_position)

	# Check if the raycast hit something
	if result != null:
		# Get the collider's parent (the unit)
		var collider = result["collider"].get_parent()
		if collider is Unit and collider != selected_unit:
			# Select the unit
			_set_selected_unit(collider)
			return true
	return false

# Performs a raycast to get mouse position in the world
func get_mouse_position(camera: Camera3D, mouse_position: Vector2):
	# Ensure RayCast3D is available
	if raycast == null or not raycast.is_inside_tree():
		return null

	# Calculate ray origin and direction
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)

	# Update RayCast3D's position and target
	raycast.global_transform.origin = ray_origin
	raycast.target_position = ray_origin + ray_direction * 1000  # Extend ray

	# Force raycast update
	raycast.force_raycast_update()

	# Return collision data if a collision occurred
	if raycast.is_colliding():
		print(raycast.get_collider())
		return {
			"position": raycast.get_collision_point(),
			"normal": raycast.get_collision_normal(),
			"collider": raycast.get_collider()
		}

	# Return null if no collision
	return null

# Sets the selected unit and emits a signal
func _set_selected_unit(unit: Unit) -> void:
	selected_unit = unit
	SignalBus.selected_unit_changed.emit(unit_action_system)

# Retrieves the currently selected unit
func get_selected_unit() -> Unit:
	return selected_unit
