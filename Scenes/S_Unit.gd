class_name Unit
extends Node3D
## Unit base class that contains functionality general to all units in combat.

# Target position the unit is moving towards
var target_position: Vector3

# Movement speed of the unit
const MOVE_SPEED: float = 4.0

# Distance threshold to stop moving when close to the target
const STOPPING_DISTANCE: float = 0.1

# Called every frame. 'delta' is the time passed since the previous frame
func _process(delta: float) -> void:
	# Move towards the target position if the unit is far enough
	move_towards_target(delta)
	
	# If right mouse button is clicked, perform raycast and set new target
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		update_target_position()

# Moves the unit towards the target position
func move_towards_target(delta: float) -> void:
	# Only move if the unit is farther than the stopping distance from the target
	if global_transform.origin.distance_to(target_position) > STOPPING_DISTANCE:
		var move_direction: Vector3 = (target_position - global_transform.origin).normalized()
		global_transform.origin += move_direction * MOVE_SPEED * delta

# Updates the target position based on the raycast from the mouse click
func update_target_position() -> void:
	# Get camera, world, and mouse position from the viewport
	var camera: Camera3D = get_viewport().get_camera_3d()
	var world: World3D = get_world_3d()
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	
	# Perform raycast by calling the static function in the MouseWorld class
	var result: Dictionary = MouseWorld.get_mouse_position(camera, world, mouse_position)
	
	# If raycast hit an object, update the unit's target position
	if result.size() > 0:
		move(result["position"])

# Sets a new target position for the unit
func move(new_target_position: Vector3) -> void:
	self.target_position = new_target_position
