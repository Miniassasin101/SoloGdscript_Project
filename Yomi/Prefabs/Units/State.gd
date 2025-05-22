@tool

class_name State
extends Node


signal startup_complete
signal active_complete
signal recovery_complete

@export_tool_button("UpdateMarkers") var update_markers_action: Callable = update_markers
@export_tool_button("UpdateTimeVal") var update_time_action: Callable = update_time_vals

enum StatePhase {
	INACTIVE,
	STARTUP,
	ACTIVE,
	RECOVERY
}

# Updates markers from timevals
#@export_tool_button("UpdateMarkers") v
# Updates timevals from markers


@export var state_name: String

@export var startup_animation: Animation
@export var startup_end_time: float = 0.0

@export var active_animation: Animation

@export var recovery_animation: Animation

# Real time until the various phases end.
# Calculated when state starts 
# (Ex: Windup normally takes 100 beats or 1 second at F9, but with an A2 Speed, it could reduce the
# beats to 50, meaning windup only takes .5 seconds for that attack. An ability or upgrade could
# reduce the base beats for an attack at the cost of hitstun or damage.
var beats_left: int = 0


var turn_state: StatePhase = StatePhase.INACTIVE:
	set(value):
		turn_state = value
		#_on_turn_state_changed()


var is_stance: bool = false

var is_running: bool = false


func update_markers() -> void:
	print_debug("Markers Working")
	pass


func update_time_vals() -> void:
	print_debug("Time_Vals Working")
	pass


func play_beats(num_beats: int = 1) -> void:
	pass
