class_name DynamicDashBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var dash_force: float = get_beat_value_by_name("dash_force").value
	
	var cha: BaseChar = state.unit
	var d_request: DashPhysicsRequest = DashPhysicsRequest.new(dash_force)

	cha.queue_physics_requests([d_request])
