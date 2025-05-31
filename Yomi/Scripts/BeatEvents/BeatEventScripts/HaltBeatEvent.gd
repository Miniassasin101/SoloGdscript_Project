class_name HaltBeatEvent
extends BeatEvent



func on_beat_event(state: State) -> void:
	var unit: BaseChar = state.state_machine.unit
	unit.linear_velocity = unit.linear_velocity/2
	
	
