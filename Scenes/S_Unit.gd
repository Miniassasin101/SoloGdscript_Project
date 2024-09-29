class_name Unit
extends Node3D

## Unit base class that contains functionality general to all units in combat.

@export var animation_tree: AnimationTree
@onready var mouse_world: MouseWorld = $"../MouseWorld"
  # Reference to the MouseWorld node

# Target position the unit is moving towards
var target_position: Vector3

# Movement speed of the unit
const MOVE_SPEED: float = 4.0

# Distance threshold to stop moving when close to the target
const STOPPING_DISTANCE: float = 0.1

func _ready() -> void:
	target_position = global_transform.origin

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
		# Calculate the movement direction
		var move_direction: Vector3 = (target_position - global_transform.origin).normalized()

		# Move towards the target
		global_transform.origin += move_direction * MOVE_SPEED * delta
		
		# Smoothly rotate the unit towards the movement direction
		var target_rotation = transform.basis.looking_at(-move_direction, Vector3.UP)
		var rotate_speed: float = 8.0
		global_transform.basis = global_transform.basis.slerp(target_rotation, delta * rotate_speed)  # Adjust the multiplier for smoother turning

		# Set the walking animation condition
		animation_tree.set("parameters/conditions/IsWalking", true)
	else:
		# If not moving, set the walking condition to false
		animation_tree.set("parameters/conditions/IsWalking", false)

# Updates the target position based on the raycast from the mouse click
func update_target_position() -> void:
	# Get camera and mouse position from the viewport
	var camera: Camera3D = get_viewport().get_camera_3d()
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	
	# Perform raycast by calling the non-static function in the MouseWorld instance
	var result: Dictionary = mouse_world.get_mouse_position(camera, mouse_position)
	
	# If raycast hit an object, update the unit's target position
	if result.size() > 0 and result.has("position"):
		move(result["position"])

# Sets a new target position for the unit
func move(new_target_position: Vector3) -> void:
	self.target_position = new_target_position
