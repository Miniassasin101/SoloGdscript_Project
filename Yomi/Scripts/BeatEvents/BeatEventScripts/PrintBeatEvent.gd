class_name PrintBeatEvent
extends BeatEvent

@export var spawn_text: String = "None"
@export var text_color: Color = Color.ALICE_BLUE
@export var scale: float = 1.0


func on_beat_event(state: State) -> void:
	BeatUtils.spawn_text_line(state.state_machine.unit, spawn_text + " " + str(state.beat_counter), text_color, scale)
	
	
