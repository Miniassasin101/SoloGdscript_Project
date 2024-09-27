class_name MouseWorld
extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Get the camera and create a ray from the camera to the mouse position
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)

	# Create a PhysicsRayQueryParameters3D object to define the ray
	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = ray_origin
	ray_params.to = ray_origin + ray_direction * 1000  # Ray length set to 1000 units

	# Perform the raycast
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_params)

	# Log the raycast result
	print_debug(result)
