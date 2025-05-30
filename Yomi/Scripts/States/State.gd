@tool

class_name State
extends Node


enum StatePhase { INACTIVE, STARTUP, ACTIVE, RECOVERY }

signal startup_begin
signal startup_complete
signal active_complete
signal recovery_complete

#@export_tool_button("UpdateMarkers") var update_markers_action: Callable = update_markers
@export_tool_button("UpdateTimeVal") var update_time_action: Callable = update_time_vals


@export var state_machine: StateMachine


@export var state_name: String
@export var is_action: bool = true
@export var is_loop: bool = false
@export var actionable_at: StatePhase = StatePhase.ACTIVE

@export var startup_animation: Animation
@export var startup_beats: int = 10           # in frames

@export var active_animation: Animation       # played by parent’s AnimationPlayer

@export var recovery_animation: Animation

@export var beat_events: Array[BeatEvent] = []



# Real time until the various phases end.
# Calculated when state starts 
# (Ex: Windup normally takes 100 beats or 1 second at F9, but with an A2 Speed, it could reduce the
# beats to 50, meaning windup only takes .5 seconds for that attack. An ability or upgrade could
# reduce the base beats for an attack at the cost of hitstun or damage.
var _phase: StatePhase = StatePhase.INACTIVE
var is_running: bool = false
var beat_counter: int = 0
var beats_left: int = 0




"""
func update_markers() -> void:
	#var state_machine: StateMachine = get_parent() as StateMachine
	#var anim_player: AnimationPlayer = state_machine.animation_player\
	if startup_animation:
		print("Startup_anim: ", startup_animation.resource_name)
	if startup_animation.has_marker("Startup End"):
		print("has marker")
		startup_animation.remove_marker("Startup End")

	startup_animation.add_marker("Startup End", startup_end_time)
	#anim_player.add_marker()
	print_debug("Markers Working: ", str(startup_end_time))
	pass
"""

func _ready() -> void:
	if state_machine == null:
		state_machine = get_parent()

func update_time_vals() -> void:
	print_debug("Time_Vals Working")
	pass

# call this before each new run
func reset_state() -> void:
	_phase = StatePhase.INACTIVE
	is_running = false
	beat_counter = 0
	beats_left = 0

func play_beats(num_beats: int = 1) -> void:
	if not is_running:
		# first beat → enter STARTUP
		is_running = true
		_phase = StatePhase.STARTUP
		beats_left = startup_beats
		beat_counter = 0
		startup_begin.emit()
		play_animation()
	else:
		beats_left -= num_beats
		beat_counter += num_beats
		activate_beat_events()
	# still waiting?
	if beats_left > 0:
		return

	# handle phase completion (allowing small overflow)
	var overflow: int = -beats_left
	match _phase:
		StatePhase.STARTUP:
			emit_signal("startup_complete")
			_maybe_notify_parent(StatePhase.STARTUP)
			_enter_active(overflow)

		StatePhase.ACTIVE:
			emit_signal("active_complete")
			_maybe_notify_parent(StatePhase.ACTIVE)
			_enter_recovery(overflow)

		StatePhase.RECOVERY:
			emit_signal("recovery_complete")
			_maybe_notify_parent(StatePhase.RECOVERY)
			# done with this State
			is_running = false


func play_animation() -> void:
	var anim_name: String = ""
	match _phase:
		StatePhase.STARTUP:
			anim_name = startup_animation.resource_name if startup_animation else ""
		
		StatePhase.ACTIVE:
			anim_name = active_animation.resource_name if active_animation else ""
		
		StatePhase.RECOVERY:
			anim_name = recovery_animation.resource_name if recovery_animation else ""
	
	if anim_name == "" or state_machine.animation_manager.active_anim_name == anim_name:
		print_debug("Animation continuing: " + anim_name)
		return
	
	state_machine.play_animation(anim_name)

func _maybe_notify_parent(phase_done: StatePhase) -> void:
	if phase_done == actionable_at:
		var sm := state_machine
		if sm:
			sm.on_state_actionable()

func _enter_active(overflow: int) -> void:
	_phase = StatePhase.ACTIVE
	# duration in beats = animation length (s) * fps(60) * scale
	var dur: float = active_animation.length * 60.0 * (get_parent().anim_scale) if active_animation else 1
	
	beats_left = int(ceil(dur)) + overflow
	play_animation()

func _enter_recovery(overflow: int) -> void:
	_phase = StatePhase.RECOVERY
	var dur: float = recovery_animation.length * 60.0 * (get_parent().anim_scale) if recovery_animation else 1
	beats_left = int(ceil(dur)) + overflow
	play_animation()


func activate_beat_events() -> void:
	for beat_event: BeatEvent in beat_events:
		if beat_event.is_beat_in_range(beat_counter):
			beat_event.on_beat_event(self)

# Prompts things like sliders or input while action is focused to change things like target.
func on_action_focused() -> void:
	print_debug("focused")
	pass


func on_action_unfocused() -> void:
	print_debug("unfocused")
	pass


func on_action_locked_in() -> void:
	print_debug(state_name + "locked in")
	pass
