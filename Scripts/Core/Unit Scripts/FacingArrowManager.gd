class_name FacingArrowManager
extends Node3D

# Reference to the parent unit
@export var unit: Unit

# Materials for each gait
@export var blue_material: StandardMaterial3D
@export var green_material: StandardMaterial3D
@export var orange_material: StandardMaterial3D
@export var red_material: StandardMaterial3D

# Arrow mesh and rotation settings
@export var arrow_mesh: MeshInstance3D = null
@export var rotate_speed: float = 5.0

# Pulse animation config
@export var pulse_scale: Vector3 = Vector3(1.3, 1.3, 1.3)
@export var pulse_duration: float = 0.15
@export var pulse_transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var pulse_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

var pulse_tween: Tween = null
var original_scale: Vector3

# Internal state for managing rotation
var is_rotating: bool = false
var target_rotation: Basis

func _ready() -> void:
	if unit.has_method("set_facing"):
		unit.facing_changed.connect(_on_facing_changed)
	unit.gait_changed.connect(_on_gait_changed)
	
	original_scale = arrow_mesh.scale

func _process(delta: float) -> void:
	if is_rotating:
		global_transform.basis = global_transform.basis.slerp(target_rotation, delta * rotate_speed)
		global_transform.basis = global_transform.basis.orthonormalized()
		if global_transform.basis.z.normalized().dot(target_rotation.z.normalized()) > 0.9999:
			is_rotating = false
			global_transform.basis = target_rotation

func _on_facing_changed(new_facing: int) -> void:
	rotate_arrow_towards_facing(new_facing)

func _on_gait_changed(new_gait: int) -> void:
	set_arrow_gait_color(new_gait)
	animate_arrow_pulse()

func set_arrow_visibility(is_vis: bool) -> void:
	set_visible(is_vis)

func set_arrow_gait_color(new_gait: int) -> void:
	match new_gait:
		Utilities.MovementGait.HOLD_GROUND:
			arrow_mesh.set_surface_override_material(0, blue_material)
		Utilities.MovementGait.WALK:
			arrow_mesh.set_surface_override_material(0, green_material)
		Utilities.MovementGait.RUN:
			arrow_mesh.set_surface_override_material(0, orange_material)
		Utilities.MovementGait.SPRINT:
			arrow_mesh.set_surface_override_material(0, red_material)
		_:
			push_error("No gait on ", unit.name)
			arrow_mesh.set_surface_override_material(0, blue_material)  # fallback

func animate_arrow_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()

	arrow_mesh.scale = original_scale

	pulse_tween = create_tween().bind_node(self)
	pulse_tween.set_trans(pulse_transition_type)
	pulse_tween.set_ease(pulse_ease_type)

	pulse_tween.tween_property(arrow_mesh, "scale", pulse_scale, pulse_duration)
	pulse_tween.tween_property(arrow_mesh, "scale", original_scale, pulse_duration)

func rotate_arrow_towards_facing(new_facing: int) -> void:
	var direction: Vector3
	match new_facing:
		2:  # South
			direction = Vector3(0, 0, -1)
		3:  # East
			direction = Vector3(1, 0, 0)
		0:  # North
			direction = Vector3(0, 0, 1)
		1:  # West
			direction = Vector3(-1, 0, 0)

	target_rotation = Basis.looking_at(direction, Vector3.UP)
	is_rotating = true
