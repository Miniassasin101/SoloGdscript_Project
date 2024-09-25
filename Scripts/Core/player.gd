extends CharacterBody3D

# Declare all the variables from the image with appropriate types
@onready var spring_arm: SpringArm3D = $CamOrigin/SpringArm3D

var Zoom_Desired: float
var Zoom_Min: float
var Zoom_Max: float
var Zoom_Speed: float
var Zoom_Interp: float

# Location
var Location_Desired: Vector3
var Location_Speed: float
var Location_Interp: float

# Rotation
var Rotation_Desired: Vector3
var Angle_Rotation_Desired: Vector3
var Rotation_Speed: float
var Rotation_Interp: float

func _ready():
	# Initialize the variables with default values if needed
	Zoom_Desired = 10
	Zoom_Min = 5.0
	Zoom_Max = 3000.0
	Zoom_Speed = 10.0
	Zoom_Interp = 5

	# Set the desired location to the current position of the CharacterBody3D
	Location_Desired = transform.origin
	Location_Speed = 1.0
	Location_Interp = 5

	# Set the desired rotation to the current rotation of the CharacterBody3D
	Rotation_Desired = rotation
	Angle_Rotation_Desired = spring_arm.rotation
	Rotation_Speed = 1.0
	Rotation_Interp = 5

func _physics_process(delta: float):
	# Update Zoom (SpringArm Length)
	var current_length = spring_arm.spring_length
	var new_length = lerp(current_length, Zoom_Desired, clamp(delta * Zoom_Interp, 0, 1))
	spring_arm.spring_length = new_length
	# Interpolate rotation
	var current_rotation = spring_arm.rotation
	var new_rotation = current_rotation.lerp(Angle_Rotation_Desired, clamp(delta * Rotation_Interp, 0, 1))
	spring_arm.rotation = new_rotation

	# Interpolate actor location
	global_transform.origin = global_transform.origin.lerp(Location_Desired, clamp(delta * Location_Interp, 0, 1))

	# Interpolate actor rotation
	rotation = rotation.lerp(Rotation_Desired, clamp(delta * Rotation_Interp, 0, 1))
	
	# Handle movement (forward/backward) using the "Forward" axis
	var forward_input = Input.get_axis("back", "forward") * Location_Speed
	Location_Desired += transform.basis.z * -forward_input  # Move forward/backward along the Z-axis

	# Handle movement (right/left) using the "Right" axis
	var right_input = Input.get_axis("left", "right") * Location_Speed
	Location_Desired += transform.basis.x * right_input  # Move right/left along the X-axis
	
	#var zoom_input = Input.get_axis("zoom_in", "zoom_out")
	#var zoom_clamp = Zoom_Desired + (zoom_input * Zoom_Speed)
	#Zoom_Desired = clamp(zoom_clamp, Zoom_Min, Zoom_Max)

	if Input.is_action_just_pressed("zoom_in"):
		var zoom_input = Input.get_action_strength("zoom_in") * Zoom_Speed
		var zoom_clamp = Zoom_Desired + zoom_input
		print(zoom_clamp)
		Zoom_Desired = clamp(Zoom_Desired, Zoom_Min, Zoom_Max)


	# Handle rotation (left/right) using actions "rotate_left" and "rotate_right"
	if Input.is_action_just_pressed("rotate_right"):
		Rotation_Desired.y -= deg_to_rad(45)  # Rotate right by 45 degrees
	if Input.is_action_just_pressed("rotate_left"):
		Rotation_Desired.y += deg_to_rad(45)  # Rotate left by 45 degrees
