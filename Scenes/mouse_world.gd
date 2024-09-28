class_name MouseWorld
extends Node3D

# Layer mask for detecting objects on the second layer (layer 2 is represented by 1 << 1)
const LAYER_MASK: int = 1 << 1

# Called every frame. 'delta' is the time passed since the previous frame
func _process(_delta: float) -> void:
	# Get the active 3D camera from the viewport
	var camera: Camera3D = get_viewport().get_camera_3d()

	# Perform the raycast and move the node if a hit is detected
	if camera != null:
		var result = get_mouse_position(camera, get_world_3d(), get_viewport().get_mouse_position())
		if result.size() > 0:
			# Update the node's position to the raycast hit position
			global_transform.origin = result["position"]

# Static method to handle raycasting logic
static func get_mouse_position(camera: Camera3D, world: World3D, mouse_position: Vector2) -> Dictionary:
	# Create a ray from the camera towards the mouse position
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)

	# Create the ray parameters for the raycast
	var ray_params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_params.from = ray_origin  # Start of the ray (camera position)
	ray_params.to = ray_origin + ray_direction * 500  # End of the ray (direction scaled by 500 units)
	ray_params.collision_mask = LAYER_MASK  # Only detect objects on layer 2

	# Perform the raycast using the physics world state
	var space_state = world.direct_space_state
	var result = space_state.intersect_ray(ray_params)

	return result
