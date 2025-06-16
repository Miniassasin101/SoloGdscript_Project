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

## The amount of uniform drag this body experiences. This scales with the velocity
@export var drag_force: float = 0.1
## The amount of air drag this body experiences. This scales with the velocity
@export var air_drag_force: float = 0.1
@export var air_friction_multiplier: float = 1.0
## The density of the fluid the body is moving in. By default it's set to the density of air.
@export var fluid_density: float = 1.293

@export var static_friction_coefficient: float = 0.6
@export var kinetic_friction_coefficient: float = 0.4


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
	
	
	#apply_drag(delta)
	
	apply_friction(delta)
	
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




func apply_friction(delta: float) -> void:
	if is_on_floor:
		# 1) Compute the tangential velocity relative to the floor.
		var v_tan = linear_velocity - floor_normal * linear_velocity.dot(floor_normal)
		var speed = v_tan.length()
		if speed < 0.001:
			# No meaningful sliding → nothing to do.
			return

		# 2) Compute the magnitude of the normal force (≈ weight).
		#    gravity.dot(floor_normal) is negative (e.g. -9.8 on a flat floor),
		#    so we invert it to get a positive weight.
		var normal_force = mass * -gravity.dot(floor_normal) * weight_scale

		# 3) Decide static vs. kinetic friction:
		#    If the impulse needed to stop in this frame is less
		#    than μ_static·N, we “grab” and cancel sliding entirely.
		var stop_impulse_mag = mass * speed
		var max_static_impulse = static_friction_coefficient * normal_force * delta
		if stop_impulse_mag <= max_static_impulse:
			# static friction wins → zero out tangential velocity
			apply_central_force(-v_tan * mass)
		else:
			# kinetic friction → constant opposing force μ_k·N
			var friction_dir = -v_tan.normalized()
			var friction_force = friction_dir * (kinetic_friction_coefficient * normal_force)
			apply_central_force(friction_force)

	else:
		# Air‐drag fallback (speed² drag)
		var v = linear_velocity.length()
		if v < 0.001:
			return
		var v2 = v * v
		var cd = 2.0 * air_drag_force * air_friction_multiplier * fluid_density * v
		var fd = 0.5 * fluid_density * v2 * cd
		var drag = -linear_velocity.normalized() * fd
		# prevent over‐impulse from reversing velocity
		drag = drag.limit_length(v)
		apply_central_force(drag)


func apply_movement(delta: float):
	pass

func apply_gravity(delta: float) -> void:

	if is_on_floor or is_on_slope():

		# Project the gravity vector onto the floor normal—this
		# is the component of gravity pushing *into* the slope.
		var g = gravity  # e.g. (0, -9.8, 0)
		var into_floor: Vector3 = (floor_normal * g.dot(floor_normal)).normalized()
		var grav_scale = gravity_scale
		#if gravity_scale == default_gravity_scale:
		#	set_gravity_scale(0.0)
		#if linear_velocity.y >= 1.0:
			#into_floor = into_floor * 2
		#	pass
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
