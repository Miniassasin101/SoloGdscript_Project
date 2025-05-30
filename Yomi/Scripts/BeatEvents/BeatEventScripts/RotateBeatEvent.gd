class_name RotateBeatEvent
extends BeatEvent


@export var target_rotation: Vector3

var activated: bool = false

var unit: BaseChar = null

func on_beat_event(state: State) -> void:
	if state.beat_counter == self.event_end_beat:
		end_rotation()
		return
		
	if !activated:
		unit = state.state_machine.unit
		activated = true
		BeatUtils.spawn_text_line(state.state_machine.unit, "Rotating: " + str(target_rotation))
		BeatUtils.spawn_text_line(state.state_machine.unit, "Beats: " + str(unit.get_potential_rotation_beats(Basis.from_euler(target_rotation))))
		unit.is_rotating = true
	
	unit.set_desired_rot_basis(Basis.from_euler(target_rotation))




func end_rotation() -> void:
	if !unit:
		return
	unit.is_rotating = false
	activated = false
	unit.set_desired_rot_basis(unit.global_basis)


func set_target_rotation(in_rot: Vector3) -> void:
	target_rotation = in_rot
