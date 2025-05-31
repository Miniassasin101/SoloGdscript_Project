@tool

class_name SpinState
extends State


@export var rotation_amount_degrees: float = 0.0
@export var rotating_left: bool = true

var target_rotation: Vector3 = Vector3.ZERO

var target_basis: Basis

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
	
	arrow.global_basis = target_basis
	
	is_stopped = true
	ghost_arrow_mat.albedo_color.a = 1.0

func clear_arrow() -> void:
	for child in state_machine.unit.world_rotation_root.get_children():
		if child.name == "FacingArrowRoot":
			child.queue_free()


func _physics_process(delta: float) -> void:
	if !is_active or !rotation_arrow :
		return
	
	if Input.is_action_just_pressed("left_mouse"):
		var hovered_control = get_viewport().gui_get_hovered_control()
		if hovered_control != null:
			return
		
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
		rotation_arrow.global_rotation.x = 0
		rotation_arrow.global_rotation.z = 0
	
	target_rotation.y = rotation_arrow.get_global_rotation().y
	
	target_basis = rotation_arrow.global_basis

	
	return
	
	





func on_action_unfocused() -> void:
	super.on_action_unfocused()
	is_active = false
	is_stopped = true
	
	if rotation_arrow:
		clear_arrow()
	
	pass


func on_action_locked_in() -> void:
	super.on_action_locked_in()
	var original_event: BeatEvent = beat_events[0]
	var new_event: RotateBeatEvent = original_event.duplicate(true) as RotateBeatEvent
	beat_events.clear()
	beat_events.append(new_event)
	new_event.set_target_rotation(target_rotation)
	new_event.target_basis = target_basis
	var potential_beats: int = state_machine.unit.get_potential_rotation_beats(target_basis)#Basis.from_euler(target_rotation))
	print_debug("Potential Beats: " + str(potential_beats))
	startup_beats = potential_beats
	new_event.set_end_beat(startup_beats)
	
