class_name DynamicJumpBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var jump_force: float = get_beat_value_by_name("jump_force").value
	
	var char: BaseChar = ghost if ghost else unit
	char.jump(jump_force)
