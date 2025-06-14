class_name DynamicRotateBeatEvent
extends DynamicBeatEvent



@export var target_rotation: Vector3

var target_basis: Basis

var active: bool = false

var char: BaseChar = null


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	if state.beat_counter == event_start_beat and active == true:
		active = false
	
	if !active:
		active = true
		char = state.unit
		BeatUtils.spawn_text_line(state.state_machine.unit, "Rotating: " + str(target_rotation))
		var potential_rot_beats: int = char.get_potential_rotation_beats(target_basis)
		BeatUtils.spawn_text_line(state.state_machine.unit, "Beats: " + str(potential_rot_beats))
		if char.is_ghost:
			BeatUtils.spawn_text_line(state.state_machine.unit, "Is Ghost", Color.BROWN)
		char.is_rotating = true
		char.angular_velocity = Vector3.ZERO
		
	
	if state.beat_counter == self.event_end_beat:
		end_rotation()
		return
	if char:
		char.set_desired_rot_basis(target_basis)#Basis.from_euler(target_rotation))




func end_rotation() -> void:
	if !char:
		return
	
	char.is_rotating = false
	active = false
	char.set_desired_rot_basis(char.global_basis)
	char.global_basis = target_basis
	char.angular_velocity = Vector3.ZERO


func set_target_rotation(in_rot: Vector3) -> void:
	target_rotation = in_rot
