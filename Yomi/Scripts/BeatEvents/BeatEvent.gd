class_name BeatEvent
extends Resource

@export_range(0, 100, 1.0, "or_greater") var event_start_beat: int = 1
@export_range(0, 100, 1.0, "or_greater") var event_end_beat: int = 1

@export var is_per_beat: bool = false

var unit: BaseChar = null

var ghost: BaseChar = null

var is_activated: bool = false

var is_unique: bool = false
	

func on_beat_event(state: State) -> void:

	if !unit:
		unit = state.state_machine.unit



func is_beat_in_range(beat: int) -> bool:
	if beat in range(event_start_beat, event_end_beat + 1):
		return true
	

	
	return false




func set_start_beat(beat: int = 1) -> void:
	event_start_beat = beat

func set_end_beat(beat: int = 1) -> void:
	event_end_beat = beat

func set_start_end_beats(start_beat: int = 1, end_beat: int = 1) -> void:
	set_start_beat(start_beat)
	set_end_beat(end_beat)
