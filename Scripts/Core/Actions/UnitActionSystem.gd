class_name UnitActionSystem
extends Node

#signal selected_unit_changed(action_system)


@export var selectedUnit: Unit
@onready var level_grid: LevelGrid = $"../LevelGrid"

@export var mouse_world: MouseWorld  # Reference to the MouseWorld instance (drag and drop in editor)
@export var raycast: RayCast3D
@onready var unit_action_system: UnitActionSystem = self

@onready var camera: Camera3D = get_viewport().get_camera_3d()
const unit_LAYER_MASK: int = 1 << 3  # Layer mask for unit

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("left_mouse"):
		if (TryHandleUnitSelection()):
			return

		var mouse_grid_position = level_grid.get_grid_position(mouse_world.get_mouse_position()["position"])
		if selectedUnit:
			if selectedUnit.get_move_action().is_valid_action_grid_position(mouse_grid_position):
				selectedUnit.get_move_action().move(mouse_grid_position)


# Method to handle unit selection using MouseWorld's raycast method
func TryHandleUnitSelection() -> bool:
	# Get the mouse position in screen coordinates
	var mouse_position: Vector2 = get_viewport().get_mouse_position()

	# Use the get_mouse_position method from the MouseWorld instance to perform raycast
	var result: Dictionary = get_mouse_position(camera, mouse_position)
	
	var current_unit = selectedUnit
	
	# Check if the raycast hit something
	if result.size() > 0:
		# Check if the hit object is of type "Unit"
		var collider = result["collider"].get_parent()
		if collider is Unit and collider != current_unit:
			# Select the unit
			_set_selected_unit(collider)
			return true
	return false



func get_mouse_position(camera: Camera3D, mouse_position: Vector2) -> Dictionary:
	# Make sure the RayCast3D node is available and inside the scene tree
	if raycast == null or not raycast.is_inside_tree():
		return {}

	# Update the RayCast3D node's position and direction
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)
	
	# Set the RayCast3D node's position and direction
	raycast.global_transform.origin = ray_origin
	raycast.target_position = ray_origin + ray_direction * 1000  # Extend ray direction
	
	# Force the raycast update to check for collisions immediately
	raycast.force_raycast_update()

	# If the raycast hits something, return the collision point as a dictionary
	if raycast.is_colliding():
		print(raycast.get_collider())
		return {
			"position": raycast.get_collision_point(),
			"normal": raycast.get_collision_normal(),
			"collider": raycast.get_collider()
		}

	# If no collision, return null
	return {}

func _set_selected_unit(unit: Unit) -> void:
	selectedUnit = unit
	SignalBus.selected_unit_changed.emit(unit_action_system)

func get_selected_unit():
	return selectedUnit
