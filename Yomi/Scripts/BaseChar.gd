class_name BaseChar
extends CharacterBody3D

@export var ui_name: String = "null"


@export_category("References")
@export var move_target: Node3D
@export var state_machine: StateMachine
@export var animation_manager: AnimationManager
@export var rig: Node3D
@export var world_rotation_root: Node3D

@export_group("Markers")
@export var above_marker: Marker3D
@export_category("Parameters")
# Move Parameters
@export var move_speed: float = 1.0
@export var acceleration: float = 1.0

# Rotation Parameters
@export var is_rotating: bool = false
@export var desired_rotation_degrees: float = 0.0  # target facing
@export var test_euler: Vector3
@export var desired_rotation_basis: Basis = Basis.from_euler(Vector3.FORWARD).orthonormalized()
@export var rotation_speed: float = 1.0


var _connected_state: State = null

var meshes: Array[MeshInstance3D]

var mat_setup: bool = false

func _ready() -> void:
	meshes = get_meshes()
	setup_mesh_mats_unique()
	setup_self()
	
	state_machine.state_changed.connect(_on_state_changed)
	desired_rotation_basis = Basis.from_euler(test_euler)
	pass


func setup_self() -> void:
	await get_tree().process_frame
	state_machine.start_machine()


func _physics_process(delta: float) -> void:
	if !state_machine or state_machine.is_paused:
		return
	#process_movement(delta)
	if is_rotating:
		process_rotation(delta)

func process_movement(delta: float) -> void:
	
	var forward := basis.z
	
	velocity = velocity.move_toward(forward * move_speed, acceleration * delta)
	move_and_slide()



func process_rotation(delta: float) -> void:

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
	var step: float = rotation_speed * delta
	# turn step (radians/sec) into slerp weight
	var turn_step: float = clamp(step / angle_diff, 0.0, 1.0)

	# 5. Slerp and apply
	var new_quat: Quaternion = current_quat.slerp(target_quat, turn_step)
	global_transform.basis = Basis(new_quat).orthonormalized()


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
		var mat: ShaderMaterial = mesh.get_surface_override_material(0) as ShaderMaterial
		mesh.set_surface_override_material(0, mat.duplicate(true))



func get_rotation_beats() -> int:
	var delta: float = get_physics_process_delta_time()
	# 1. current vs target quaternion
	var current_q: Quaternion = global_transform.basis.get_rotation_quaternion()
	var target_b: Basis    = desired_rotation_basis.orthonormalized()
	var target_q: Quaternion = target_b.get_rotation_quaternion()

	# 2. how many radians left to turn
	var angle_diff: float = current_q.angle_to(target_q)

	# 3. how many radians we turn per physics frame
	var turn_per_frame: float = rotation_speed * delta
	if turn_per_frame <= 0.0:
		return INF   # or 0, or however you want to signal “never”
	
	
	# 4. beats = ceil( total_angle / angle_per_beat )
	return int(ceil(angle_diff / turn_per_frame))


func get_potential_rotation_beats(rotation_basis: Basis) -> int:
	var delta: float = get_physics_process_delta_time()
	# 1. current vs target quaternion
	var current_q: Quaternion = global_transform.basis.get_rotation_quaternion()
	var target_b: Basis    = rotation_basis.orthonormalized()
	var target_q: Quaternion = target_b.get_rotation_quaternion()

	# 2. how many radians left to turn
	var angle_diff: float = current_q.angle_to(target_q)

	# 3. how many radians we turn per physics frame
	var turn_per_frame: float = rotation_speed * delta
	if turn_per_frame <= 0.0:
		return INF   # or 0, or however you want to signal “never”
	
	
	# 4. beats = ceil( total_angle / angle_per_beat )
	return int(ceil(angle_diff / turn_per_frame))


func set_desired_rot_basis(in_basis: Basis) -> void:
	desired_rotation_basis = in_basis.orthonormalized()

func clear_rotation() -> void:
	is_rotating = false
	set_desired_rot_basis(global_basis)

func set_self_color(color: Color = Color.WHITE) -> void:
	if meshes.is_empty():
		meshes = get_meshes()
	
	for mesh in meshes:
		var mat: ShaderMaterial = mesh.get_surface_override_material(0)
		var gradtext: GradientTexture1D = GradientTexture1D.new()
		var gradient: Gradient = Gradient.new()
		gradient.set_colors([Color.BLACK, color])
		gradtext.set_gradient(gradient)
		mat.set_shader_parameter("texture_albedo", gradtext)
	


# whenever the StateMachine switches to a new State…
func _on_state_changed(new_state: State) -> void:
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
