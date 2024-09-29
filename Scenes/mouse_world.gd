class_name MouseWorld
extends Node3D

# Layer mask for detecting objects on the second layer (layer 2 is represented by 1 << 1)
const LAYER_MASK: int = 1 << 1
@export var mouse_debug_sphere: bool
# A reference to the RayCast3D node
@export var raycast: RayCast3D

# Called when the node enters the scene tree
func _ready() -> void:
	# Create and add the RayCast3D node dynamically if it's not in the scene
	if raycast == null:
		raycast = RayCast3D.new()
		raycast.collision_mask = LAYER_MASK  # Set the collision mask
		raycast.enabled = true  # Enable the RayCast3D node
		add_child(raycast)  # Add RayCast3D to the scene
	

# Called every frame. 'delta' is the time passed since the previous frame
func _process(_delta: float) -> void:
	# Get the active 3D camera from the viewport
	var camera: Camera3D = get_viewport().get_camera_3d()

	# Perform the raycast and move the node if a hit is detected
	if mouse_debug_sphere == true:
		
		if camera != null and raycast != null:
			var hit_position = get_mouse_position(camera, get_viewport().get_mouse_position())
			if hit_position:
				# Update the node's position to the raycast hit position
				global_transform.origin = hit_position["position"]

# Method to return the mouse position in world space
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
		return {
			"position": raycast.get_collision_point(),
			"normal": raycast.get_collision_normal(),
			"collider": raycast.get_collider()
		}

	# If no collision, return null
	return {}
