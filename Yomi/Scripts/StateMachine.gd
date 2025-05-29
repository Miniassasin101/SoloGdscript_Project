@tool
class_name StateMachine
extends Node

signal state_changed(new_state: State)


enum StatePhase {
	INACTIVE,
	STARTUP,
	ACTIVE,
	RECOVERY
}

@export var unit: BaseChar

@export var animation_player: AnimationPlayer

@export var animation_manager: AnimationManager

@export var idle_state: State

@export var anim_scale: float = 1.0

var is_paused: bool = true

var is_actionable: bool = false

var state_stack: Array[State]

var current_state: State = null

var beats_until_actionable: int = 1

func _ready() -> void:
	EventBus.resume.connect(unpause_animation)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if !is_paused:
		current_state.play_beats(1)

func start_machine() -> void:
	state_stack.clear()
	state_stack.append(idle_state)
	_advance_state()
	is_paused = false

func _advance_state() -> void:
	if state_stack.is_empty():
		return
	current_state = state_stack.pop_front()
	# reset and kick things off at frame 0
	current_state.reset_state()
	# notify listeners that we’ve started a fresh state
	state_changed.emit(current_state)
	current_state.play_beats(0)
	
	

func queue_state(state: State) -> void:
	state_stack.append(state)

# called by State when it’s actionable
func on_state_actionable() -> void:
	EventBus.unit_actionable.emit()
	print_debug("StateMachine: state is now actionable")
	pause_animation()


func play_animation(anim: String) -> void:
	animation_manager.play_animation(anim)

func pause_animation() -> void:
	if !is_paused:
		animation_manager.anim_pause()
		is_paused = true

func unpause_animation() -> void:
	if is_paused:
		animation_manager.anim_unpause()
		is_paused = false



func get_actions() -> Array[State]:
	var ret_array: Array[State] = []
	for child in get_children():
		if child is State:
			if child.is_action:
				ret_array.append(child)
	
	return ret_array
