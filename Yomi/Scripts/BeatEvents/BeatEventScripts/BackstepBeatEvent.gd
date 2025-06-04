class_name BackstepBeatEvent
extends BeatEvent


@export var force: float = 15.0

func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	unit.backstep(force)
	
	
