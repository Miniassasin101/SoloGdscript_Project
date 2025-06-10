class_name RigidCharacterBody3D
extends RigidBody3D




## The node used as orientation reference.
## If this node will be used for the player, this
## variable should be set to the player's camera.
## If it is null, the current node will be
## used as orientation reference.
@export var orientation_node: Node3D:
	get:
		if not orientation_node: return self
		return orientation_node

@export var weight_scale: float = 1.0
## World space gravity vector.
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
## default gravity scale:
@export var default_gravity_scale: float = 3.054
## the angle degrees that qualify as a slope
@export var max_slope_angle: float = 5.0
## The force used to jump with.
@export var jump_force: float = 5.0
## The force used to walk with.
@export var walk_force: float = 15
## The force used to run with.
@export var run_force: float = 20
## The force used for moving around when in the air.
@export var air_force: float = 5
## The amount of uniform drag this body experiences. This scales with the velocity
@export var drag_force: float = 0.1
## The amount of air drag this body experiences. This scales with the velocity
@export var air_drag_force: float = 0.1
## The density of the fluid the body is moving in. By default it's set to the density of air.
@export var fluid_density: float = 1.293


var is_on_floor: bool
var floor_normal: Vector3 = Vector3.UP
var is_on_wall: bool
var wall_normal: Vector3 = Vector3.RIGHT
var is_on_ceiling: bool
var ceiling_normal: Vector3 = Vector3.DOWN
var is_running: bool
var input_direction: Vector2
var jump_input: bool
var run_input: bool


func _ready():
	# Set up body
	axis_lock_angular_x = true
	#axis_lock_angular_y = true
	axis_lock_angular_z = true
	contact_monitor = true
	max_contacts_reported = 16
	continuous_cd = true
	
	default_gravity_scale = gravity_scale
	
	# Capture mouse
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	_process_state()
	
	process_character_input()
	
	apply_movement(delta)
	
	# Add gravity
	apply_gravity(delta)
	
	
	apply_drag(delta)
	
	reset_input()


func _process_state():
	var s: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(get_rid())
	var cc: int = s.get_contact_count()
	if cc == 0:
		is_on_floor = false
		is_on_wall = false
		is_on_ceiling = false
	for ci in cc:
		var n = s.get_contact_local_normal(ci)
		var d = n.dot(Vector3.UP)
		
		is_on_floor = d >= 0.5
		if is_on_floor:
			floor_normal = n
		else:
			floor_normal = global_basis.y
		
		is_on_wall = d < 0.5 and d > -0.5
		if is_on_wall:
			wall_normal = n
		
		is_on_ceiling = d <= -0.5
		if is_on_ceiling:
			ceiling_normal = n


func apply_drag(delta: float):
	var v = linear_velocity.length()
	var v2 = linear_velocity.length_squared()
	var effective_drag = air_drag_force if !is_on_floor else drag_force
	var cd = 2.0 * effective_drag * fluid_density * v
	var fd = 1.0/2.0 * fluid_density * v2 * cd
	var drag = -linear_velocity.normalized() * fd
	drag = drag.limit_length(linear_velocity.length())
	#if !is_on_floor and linear_velocity.y < 0:
		#drag = drag/2

	apply_central_impulse(drag * delta)


func apply_movement(delta: float):
	"""
	if Input.is_action_just_pressed("jump"):
		if is_on_floor:
			apply_central_impulse(floor_normal * jump_force)
		elif is_on_wall:
			var new_norma = (wall_normal + global_basis.y).normalized()
			apply_central_impulse(new_norma * jump_force)
	if Input.is_action_just_pressed("run") and is_on_floor:
		is_running = true
	"""
	var forward = floor_normal.cross(orientation_node.global_basis.x)
	var right = forward.cross(floor_normal)
	var dir = ((forward * input_direction.y) + (right * input_direction.x)).normalized()
	if dir:
		var move_forc = air_force if not is_on_floor else run_force if is_running else walk_force
		apply_central_impulse(dir * move_forc * delta)
	elif is_running:
		is_running = false

func apply_gravity(delta: float) -> void:

	if is_on_floor and is_on_slope():

		# Project the gravity vector onto the floor normal—this
		# is the component of gravity pushing *into* the slope.
		var g = gravity  # e.g. (0, -9.8, 0)
		var into_floor: Vector3 = (floor_normal * g.dot(floor_normal)).normalized()
		var grav_scale = gravity_scale
		#if gravity_scale == default_gravity_scale:
		#	set_gravity_scale(0.0)
		if linear_velocity.y >= 1.0:
			into_floor = into_floor * 2
			pass
		apply_central_force(into_floor * weight_scale)
	else:
		#if gravity_scale != default_gravity_scale:
		#	set_gravity_scale(default_gravity_scale)
		# In the air: apply full gravity
		apply_central_force(gravity * weight_scale)# * delta)
		pass


func process_character_input():
	pass

func is_on_slope(threshold_degrees: float = max_slope_angle) -> bool:
	if not is_on_floor:
		return false
	var angle = rad_to_deg(acos(floor_normal.dot(Vector3.UP)))
	return angle > 0.01 and angle <= threshold_degrees


func reset_input():
	input_direction = Vector2.ZERO
	jump_input = false
	run_input = false
