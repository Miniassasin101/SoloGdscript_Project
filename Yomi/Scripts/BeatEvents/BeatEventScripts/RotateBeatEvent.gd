class_name RotateBeatEvent
extends BeatEvent


@export var target_rotation: Vector3

var target_basis: Basis

var activated: bool = false

var unit: BaseChar = null

func on_beat_event(state: State) -> void:
		
	if !activated:
		unit = state.state_machine.unit
		activated = true
		BeatUtils.spawn_text_line(state.state_machine.unit, "Rotating: " + str(target_rotation))
		var potential_rot_beats: int = unit.get_potential_rotation_beats(target_basis)
		BeatUtils.spawn_text_line(state.state_machine.unit, "Beats: " + str(potential_rot_beats))
		unit.is_rotating = true
		unit.angular_velocity = Vector3.ZERO
	
	if state.beat_counter == self.event_end_beat:
		end_rotation()
		return
	
	unit.set_desired_rot_basis(target_basis)#Basis.from_euler(target_rotation))




func end_rotation() -> void:
	if !unit:
		return
	unit.is_rotating = false
	activated = false
	unit.set_desired_rot_basis(unit.global_basis)
	unit.global_basis = target_basis
	unit.angular_velocity = Vector3.ZERO


func set_target_rotation(in_rot: Vector3) -> void:
	target_rotation = in_rot
