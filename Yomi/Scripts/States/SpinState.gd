@tool

class_name SpinState
extends State


@export var rotation_amount_degrees: float = 0.0
@export var rotating_left: bool = true

var target_rotation: Vector3 = Vector3.ZERO

@export var rotation_arrow_scene: PackedScene = null

@export var ghost_arrow_mat: StandardMaterial3D

var rotation_arrow: Node3D = null

var rotation_arrow_mesh: MeshInstance3D = null

var is_active: bool = false

var is_stopped: bool = false

# Prompts things like sliders or input while action is focused to change things like target.
func on_action_focused() -> void:
	super.on_action_focused()
	
	is_active = true
	
	clear_arrow()
	setup_arrow()
	
	
	pass

func setup_arrow() -> void:
	var arrow: Node3D = rotation_arrow_scene.instantiate() as Node3D
	
	arrow.get_child(0).set_surface_override_material(0, ghost_arrow_mat)
	
	state_machine.unit.world_rotation_root.add_child(arrow)
	
	rotation_arrow = arrow
	
	rotation_arrow_mesh = arrow.get_child(0) as MeshInstance3D
	
	is_stopped = true
	ghost_arrow_mat.albedo_color.a = 1.0

func clear_arrow() -> void:
	for child in state_machine.unit.world_rotation_root.get_children():
		child.queue_free()


func _physics_process(delta: float) -> void:
	if !is_active or !rotation_arrow :
		return
	
	if Input.is_action_just_pressed("left_mouse"):
		if is_stopped:
			is_stopped = false
			ghost_arrow_mat.albedo_color.a = 7.0
		else:
			is_stopped = true
			ghost_arrow_mat.albedo_color.a = 1.0
	
	if is_stopped:
		return
	
	var mouse_pos: Vector3 = MouseController.instance.current_hovered_position
	
	if mouse_pos:
		rotation_arrow.look_at(mouse_pos, Vector3.UP, true)
	
	target_rotation.y = rotation_arrow.get_global_rotation().y
	
	return
	
	





func on_action_unfocused() -> void:
	super.on_action_unfocused()
	is_active = false
	
	if rotation_arrow:
		clear_arrow()
	
	pass


func on_action_locked_in() -> void:
	super.on_action_locked_in()
	var event: RotateBeatEvent = beat_events[0] as RotateBeatEvent
	event.set_target_rotation(target_rotation)
	var potential_beats: int = state_machine.unit.get_potential_rotation_beats(Basis.from_euler(target_rotation))
	print_debug("Potential Beats: " + str(potential_beats))
	event.set_end_beat(state_machine.unit.get_potential_rotation_beats(Basis.from_euler(target_rotation)))
	startup_beats = potential_beats + 1
