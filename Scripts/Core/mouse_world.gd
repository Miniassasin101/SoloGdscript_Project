class_name MouseWorld
extends Node3D

# Layer mask for detecting objects on layer 2 (1 << 1)
const LAYER_MASK: int = 1 << 1

# Toggle for showing a debug sphere at the mouse position
@export var mouse_debug_sphere: bool

# Reference to the RayCast3D node
@export var raycast: RayCast3D

# Reference to the active Camera3D
var camera: Camera3D

# Mouse position in screen coordinates
var mouse_position: Vector2

# Called when the node enters the scene tree
func _ready() -> void:
	camera = get_viewport().get_camera_3d()
	# Create and add the RayCast3D node dynamically if it's not in the scene
	if raycast == null:
		raycast = RayCast3D.new()
		raycast.collision_mask = LAYER_MASK  # Set the collision mask
		raycast.enabled = true  # Enable the RayCast3D node
		add_child(raycast)  # Add RayCast3D to the scene

# Called every frame
func _process(_delta: float) -> void:
	# Update mouse position
	adjust_mouse_position()
	# Perform the raycast and move the node if a hit is detected
	if mouse_debug_sphere:
		if camera != null and raycast != null:
			var hit_position = get_mouse_position()
			if hit_position != null:
				# Update the node's position to the raycast hit position
				global_transform.origin = hit_position["position"]

# Returns the mouse position in world space as a Dictionary
func get_mouse_position():
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
		return {
			"position": raycast.get_collision_point(),
			"normal": raycast.get_collision_normal(),
			"collider": raycast.get_collider()
		}

	# Return null if no collision
	return null

# Updates the mouse position variable
func adjust_mouse_position() -> void:
	mouse_position = get_viewport().get_mouse_position()
