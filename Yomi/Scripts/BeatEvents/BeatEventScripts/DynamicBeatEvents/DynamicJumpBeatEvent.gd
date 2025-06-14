class_name DynamicJumpBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var jump_force: float = get_beat_value_by_name("jump_force").value
	
	var cha: BaseChar = state.unit
	
	var up_dir := cha.global_transform.basis.y
	
	var j_request: GeneralImpulsePhysicsRequest = GeneralImpulsePhysicsRequest.new(up_dir, jump_force)
	
	cha.queue_physics_request(j_request)
