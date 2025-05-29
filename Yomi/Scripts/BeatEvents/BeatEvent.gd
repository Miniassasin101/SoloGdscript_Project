class_name BeatEvent
extends Resource

@export_range(0, 100, 1.0, "or_greater") var event_start_beat: int = 1
@export_range(0, 100, 1.0, "or_greater") var event_end_beat: int = 1

@export var is_per_beat: bool = false

func on_beat_event(state: State) -> void:
	pass

func is_beat_in_range(beat: int) -> bool:
	if beat in range(event_start_beat, event_end_beat + 1):
		return true
	return false
