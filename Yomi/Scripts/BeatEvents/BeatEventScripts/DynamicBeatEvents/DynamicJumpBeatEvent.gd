class_name DynamicJumpBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var jump_force: float = get_beat_value_by_name("jump_force").value
	
	
	unit.jump(jump_force)
