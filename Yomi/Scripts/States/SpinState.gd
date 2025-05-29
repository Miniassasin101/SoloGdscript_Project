@tool

class_name SpinState
extends State


@export var rotation_amount_degrees: float = 0.0
@export var rotating_left: bool = true

var target_rotation: Vector3 = Vector3.FORWARD

var rotation_arrow: PackedScene = null

var ghost_arrow_mat: StandardMaterial3D


var is_active: bool = false

# Prompts things like sliders or input while action is focused to change things like target.
func on_action_focused() -> void:
	super.on_action_focused()
	
	is_active = true
	
	
	
	pass

func setup_arrow() -> void:
	var arrow: MeshInstance3D = rotation_arrow.instantiate() as MeshInstance3D
	
	arrow.set_surface_override_material(0, ghost_arrow_mat)
	
	state_machine.unit.add_child(arrow)


func _physics_process(delta: float) -> void:
	





func on_action_unfocused() -> void:
	super.on_action_unfocused()
	is_active = false
	pass
