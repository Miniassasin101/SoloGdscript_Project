class_name BaseChar
extends RigidCharacterBody3D

signal rotation_completed

@export var ui_name: String = "null"

@export_category("Stats")
@export var health: int = 10
@export var max_health: int = 10

@export_category("References")
@export var move_target: Node3D
@export var state_machine: StateMachine
@export var animation_manager: AnimationManager
@export var rig: Node3D
@export var world_rotation_root: Node3D
@export var selection_visual: GridSystemVisualSingle
@export var ghost_mat: StandardMaterial3D

@export_group("Markers")
@export var above_marker: Marker3D
@export_category("Parameters")

@export var rot_speed: float = 3.0  # radians/sec

# Move Parameters
@export var move_speed: float = 1.0
@export var acceleration: float = 1.0

# Rotation Parameters
@export var is_rotating: bool = false
@export var desired_rotation_degrees: float = 0.0  # target facing
@export var test_euler: Vector3
@export var desired_rotation_basis: Basis = Basis.from_euler(Vector3.FORWARD).orthonormalized()



var _connected_state: State = null

var meshes: Array[MeshInstance3D]

var mat_setup: bool = false

var physics_are_paused: bool = false

var saved_linear_velocity: Vector3

var saved_angular_velocity: Vector3

var physics_request_queue: Array[PhysicsRequest] = []

## Incredibly important bool that separates ghosts from real characters.

var is_ghost: bool = false


func _ready() -> void:
	super._ready()
	meshes = get_meshes()
	setup_mesh_mats_unique()

	state_machine.state_changed.connect(_on_state_changed)
	desired_rotation_basis = Basis.from_euler(test_euler)
	
	pause_physics()
	
	if !is_ghost:
		EventBus.pause.connect(pause_physics)
		EventBus.resume.connect(resume_physics)
	
	EventBus.hide_all_selection_visuals.connect(hide_selection_visuals)
	
	EventBus.apply_physics_requests.connect(_on_apply_physics_requests)








func _physics_process(delta: float) -> void:
	if physics_are_paused:
		return
	
	super._physics_process(delta)
	
	if is_rotating:
		process_rotation(delta)


func beat_physics_process(delta: float = 0.0) -> void:
	if !state_machine or state_machine.is_paused:
		if !physics_are_paused:
			pause_physics()
		return
	
	if physics_are_paused:
		resume_physics()
	
	state_machine.beat_physics_process(delta)


func pause_physics() -> void:
	saved_linear_velocity = linear_velocity
	saved_angular_velocity = angular_velocity
	physics_are_paused = true
	freeze = true


func resume_physics() -> void:
	
	
	physics_are_paused = false
	freeze = false
	linear_velocity = saved_linear_velocity
	if freeze:
		pass
	angular_velocity = saved_angular_velocity



#region Physics Functions
func _apply_rotation(delta: float) -> void:
	# compute yaw angles
	var current_yaw = global_transform.basis.get_euler().y
	var target_yaw  = desired_rotation_basis.get_euler().y
	# shortest signed difference
	var diff = wrapf(target_yaw - current_yaw, -PI, PI)

	# if we’re almost there, snap & stop
	if abs(diff) < 0.013:
		# zero out spin and snap exactly
		angular_velocity = Vector3.ZERO
		global_transform.basis = desired_rotation_basis.orthonormalized()
		is_rotating = false
		rotation_completed.emit()
		return

	# otherwise spin at fixed rate toward the target
	# sign(diff) gives direction; rotation_speed is rad/sec
	angular_velocity.y = rot_speed * sign(diff)





func fall(force: float = 15.0) -> void:
	var down_dir := -global_transform.basis.y
	apply_central_impulse(down_dir * force)


func queue_physics_request(request: PhysicsRequest) -> void:
	physics_request_queue.append(request)

func queue_physics_requests(requests: Array[PhysicsRequest]) -> void:
	physics_request_queue.append_array(requests)

func _on_apply_physics_requests() -> void:
	if physics_request_queue.is_empty():
		if !is_ghost:
			pass
		return
	
	if !is_ghost:
		pass
	
	for req in physics_request_queue:
		req.apply(self)
	print_debug("Frame: " + str(state_machine.current_state.beat_counter))
	physics_request_queue.clear()
	

func process_movement(delta: float) -> void:

	var forward := basis.z

	#velocity = velocity.move_toward(forward * move_speed, acceleration * delta)
	#move_and_slide()


func process_rotation(delta: float) -> void:
#endregion

	# 1. Fetch current & target quaternions
	var current_quat: Quaternion = global_transform.basis.get_rotation_quaternion()
	var target_basis: Basis = desired_rotation_basis.orthonormalized()
	var target_quat: Quaternion = target_basis.get_rotation_quaternion()

	# 2. Compute the angular difference
	var angle_diff: float = current_quat.angle_to(target_quat)
	var snap_threshold: float = deg_to_rad(0.5)  # adjust tolerance here

	# 3. If we're within threshold, snap to exact target and finish
	if angle_diff < snap_threshold:
		global_transform.basis = target_basis
		is_rotating = false
		#rotation_completed.emit()
		return

	# 4. Otherwise, compute a proper interpolation factor
	var step: float = rot_speed * delta
	# turn step (radians/sec) into slerp weight
	var turn_step: float = clamp(step / angle_diff, 0.0, 1.0)

	# 5. Slerp and apply
	var new_quat: Quaternion = current_quat.slerp(target_quat, turn_step)
	global_transform.basis = Basis(new_quat).orthonormalized()



# Ghost Functions:
func setup_from_ghost_template(ghost_t: GhostTemplate) -> void:
	var o_un: BaseChar = ghost_t.original_unit
	var g_un: BaseChar = self
	# Important setting of is_ghost happens here
	is_ghost = true
	toggle_unit_collision(false)
	global_transform = ghost_t.global_transform
	is_on_floor = g_un.is_on_floor
	saved_linear_velocity = ghost_t.saved_linear_velocity
	#qlinear_velocity = saved_linear_velocity
	ui_name = ghost_t.template_name
	print_debug(ui_name)
	set_self_color(Color.PURPLE)
	
	var original_state: State = ghost_t.original_current_state
	var s_name: String = ghost_t.action_override.state_name if ghost_t.is_overridden else ghost_t.current_state_name
	var initial_state: State = state_machine.get_state_by_name(s_name)
	if initial_state:
		state_machine.queue_state(initial_state)
		state_machine._advance_state()
		state_machine.current_state.beats_left = original_state.beats_left if !ghost_t.is_overridden else initial_state.beats_left
		state_machine.current_state.beat_counter = original_state.beat_counter if !ghost_t.is_overridden else initial_state.beat_counter
		state_machine.current_state._phase = original_state._phase if !ghost_t.is_overridden else initial_state._phase
		if ghost_t.is_overridden:
			initial_state.beat_events = ghost_t.action_override.beat_events
			initial_state.set_beat_events_ghost(self)
			if initial_state is SpinState:
				initial_state.ghost_spin_setup(ghost_t.action_override.target_rotation, ghost_t.action_override.target_basis)
		
		else:
			#Setup Animation
			var pb_time: float = o_un.animation_manager.get_playback_time()
			animation_manager.set_seek_playback(o_un.animation_manager.get_playback_time())
			pass
	pass




func toggle_unit_collision(unit_collision_on: bool = true) -> void:
	set_collision_layer_value(4, unit_collision_on)
	set_collision_mask_value(4, unit_collision_on)
	set_collision_layer_value(2, unit_collision_on)
	set_collision_mask_value(2, unit_collision_on)
	set_collision_layer_value(3, !unit_collision_on)
	set_collision_mask_value(3, !unit_collision_on)
	



func get_world_position_above_marker() -> Vector3:
	return above_marker.get_global_position()


func get_meshes() -> Array[MeshInstance3D]:
	if !rig:
		return []

	var array: Array[MeshInstance3D] =  []
	array.assign(rig.get_children())
	return array


func setup_mesh_mats_unique() -> void:
	for mesh in meshes:
		if is_ghost:
			return
		var mat: ShaderMaterial = mesh.get_surface_override_material(0) as ShaderMaterial
		mesh.set_surface_override_material(0, mat.duplicate(true))





func get_rotation_beats() -> int:
	# 1) fixed physics step so it works even when frozen
	var delta      := get_parent().get_physics_process_delta_time()

	# 2) how many radians remain
	var current_q  = global_transform.basis.get_rotation_quaternion()
	var target_q   = desired_rotation_basis.orthonormalized().get_rotation_quaternion()
	var angle_diff = current_q.angle_to(target_q)

	var turn_rate = rot_speed


	var turn_per_tick = turn_rate * delta
	if turn_per_tick <= 0.0:
		return INF

	# 4) always ceil so you never undercount
	return int(ceil(angle_diff / turn_per_tick))



func get_potential_rotation_beats(rotation_basis: Basis) -> int:
	print_debug("Angular Damp: " + str(angular_damp))
	# 1) fixed physics step so it works even when frozen
	var delta      := get_parent().get_physics_process_delta_time()

	# 2) how many radians remain
	var current_q  = global_transform.basis.get_rotation_quaternion()
	var target_q   = rotation_basis.orthonormalized().get_rotation_quaternion()
	var angle_diff = current_q.angle_to(target_q)


	var turn_rate = rot_speed



	var turn_per_tick = turn_rate * delta
	if turn_per_tick <= 0.0:
		return INF

	# 4) always ceil so you never undercount
	return maxi(int(ceil(angle_diff / turn_per_tick)), 1) 


func set_desired_rot_basis(in_basis: Basis) -> void:
	desired_rotation_basis = in_basis.orthonormalized()

func clear_rotation() -> void:
	is_rotating = false
	set_desired_rot_basis(global_basis)


func hide_selection_visuals() -> void:
	selection_visual.hide_self()


func set_self_color(color: Color = Color.WHITE) -> void:
	if meshes.is_empty():
		meshes = get_meshes()

	for mesh in meshes:
		if is_ghost:
			var g_mat: StandardMaterial3D = ghost_mat.duplicate(true)
			var alpha := g_mat.albedo_color.a
			
			g_mat.albedo_color = color
			
			g_mat.albedo_color.a = alpha
			mesh.set_surface_override_material(0, g_mat)
			continue
		var mat: ShaderMaterial = mesh.get_surface_override_material(0)
		var gradtext: GradientTexture1D = GradientTexture1D.new()
		var gradient: Gradient = Gradient.new()
		gradient.set_colors([Color.BLACK, color])
		gradtext.set_gradient(gradient)
		mat.set_shader_parameter("texture_albedo", gradtext)



# whenever the StateMachine switches to a new State…
func _on_state_changed(new_state: State) -> void:
	if is_ghost:
		return
	# disconnect old signals
	if _connected_state:
		_connected_state.startup_begin.disconnect(_on_startup_begin)
		_connected_state.startup_complete.disconnect(_on_startup)
		_connected_state.active_complete.disconnect(_on_active)
		_connected_state.recovery_complete.disconnect(_on_recovery)

	_connected_state = new_state

	# reset to “inactive” color when a new state begins

	set_self_color(Color.WHITE)

	# listen for each phase finishing
	_connected_state.startup_begin.connect(_on_startup_begin)
	_connected_state.startup_complete.connect(_on_startup)
	_connected_state.active_complete.connect(_on_active)
	_connected_state.recovery_complete.connect(_on_recovery)

func _on_startup_begin() -> void:
	set_self_color(Color.FOREST_GREEN)

func _on_startup() -> void:
	set_self_color(Color.RED)

func _on_active() -> void:
	set_self_color(Color.BLUE)

func _on_recovery() -> void:
	set_self_color(Color.WHITE)
