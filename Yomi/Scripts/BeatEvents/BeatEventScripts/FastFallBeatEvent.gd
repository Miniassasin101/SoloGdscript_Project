class_name FastFallBeatEvent
extends BeatEvent


@export var force: float = 15.0

func on_beat_event(state: State) -> void:
	var unit: BaseChar = state.state_machine.unit
	unit.fall(force)
	
	
