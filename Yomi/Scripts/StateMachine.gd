
class_name StateMachine
extends Node

signal state_changed(new_state: State)


enum StatePhase {
	INACTIVE,
	STARTUP,
	ACTIVE,
	RECOVERY
}

@export var unit: BaseChar = null

@export var animation_player: AnimationPlayer = null

@export var animation_manager: AnimationManager = null

@export var idle_state: State

@export var anim_scale: float = 1.0



var granted_states: Array[State] = []

var is_paused: bool = true

var is_actionable: bool = false

var state_stack: Array[State] = []

var current_state: State = null

var beats_until_actionable: int = 1

func _ready() -> void:
	
	if unit and !unit.is_ghost:
	
		EventBus.pause.connect(pause_animation)
		EventBus.resume.connect(unpause_animation)
	
	var old_children: Array = get_children()
	
	for child in old_children:
		if child is State:
			if child == idle_state:
				var new_state: State = child.duplicate()
				granted_states.append(new_state)
				idle_state = new_state
			else:
				granted_states.append(child.duplicate())
	
	for child in get_children(true):
		child.queue_free()
	for state in granted_states:
		add_child(state)
	
	if !idle_state:
		idle_state = get_state_by_name("Idle")

func _physics_process(_delta: float) -> void:
	pass
	#if !is_paused:
	#	current_state.play_beats(1)
	#	beats_until_actionable = current_state.beats_left

func start_machine() -> void:
	state_stack.clear()
	state_stack.append(idle_state)
	_advance_state()
	is_paused = false

func _advance_state() -> void:
	if state_stack.is_empty():
		return
	current_state = state_stack.pop_front() as State
	# reset and kick things off at frame 0
	current_state.reset_state()
	# notify listeners that we’ve started a fresh state
	state_changed.emit(current_state)
	current_state.play_beats(0)
	

func beat_physics_process(_delta: float) -> void:
	if !is_paused:
		if !unit.is_ghost:
			pass
		else:
			pass
		current_state.play_beats(1)
		beats_until_actionable = current_state.beats_left
		


func queue_state(state: State) -> void:
	state_stack.append(state)

# called by State when it’s actionable
func on_state_actionable() -> void:
	if unit.is_ghost:
		unit.set_self_color(Color.YELLOW)
		if current_state.state_name != "Idle":
			EventBus.prediction_pause_for_beats.emit()

		queue_state(idle_state)
		_advance_state()
		return
	is_actionable = true
	EventBus.unit_actionable.emit(unit)
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


func clear_beat_event_ghosts() -> void:
	for state in granted_states:
		for b_event in state.beat_events:
			b_event.ghost = null
			



func get_state_by_name(state_name: String = "Idle") -> State:
	var pasc_name: String = state_name.to_snake_case()
	
	for state: State in granted_states:
		if state.state_name.to_snake_case() == pasc_name:
			return state
	
	return null


func get_actions() -> Array[State]:
	var ret_array: Array[State] = []
	for child in get_children():
		if child is State:
			if child.is_action:
				ret_array.append(child)
	
	return ret_array
