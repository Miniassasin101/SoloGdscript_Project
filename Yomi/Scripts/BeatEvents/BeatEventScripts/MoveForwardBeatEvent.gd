class_name MoveForwardBeatEvent
extends BeatEvent


@export var force: float = 15.0

func on_beat_event(state: State) -> void:
	var unit: BaseChar = state.state_machine.unit
	#var for_dir := unit.global_transform.basis.z
	var for_dir := unit.floor_normal.cross(-unit.global_basis.x)
	unit.move_in_direction(for_dir, force)
	
	
