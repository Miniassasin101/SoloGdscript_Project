class_name DynamicMoveBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var move_force: float = get_beat_value_by_name("move_force").value
	
	var cha: BaseChar = state.unit
	
	var for_dir := cha.floor_normal.cross(-cha.global_basis.x)
	
	var m_request: GeneralForcePhysicsRequest = GeneralForcePhysicsRequest.new(for_dir, move_force)
	
	cha.queue_physics_request(m_request)
