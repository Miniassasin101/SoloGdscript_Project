@tool
class_name StateMachine
extends Node

@export var ui_name: String

@export var idle_state: State

@export var anim_scale: float = 1.0

var is_actionable: bool = false

var state_stack: Array[State]

var current_state: State = null

var beats_until_actionable: int = 1

func start_machine() -> void:
	state_stack.append(idle_state)
	

	pass

func next_state() -> void:
	if !state_stack.is_empty():
		var new_state: State = state_stack.pop_front()
		current_state = new_state
		

func play_beats(num_of_beats: int = 1) -> void:
	current_state.play_beats(num_of_beats)
