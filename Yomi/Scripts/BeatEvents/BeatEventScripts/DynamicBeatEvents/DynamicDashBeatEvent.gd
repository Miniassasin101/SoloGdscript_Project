class_name DynamicDashBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var dash_force: float = get_beat_value_by_name("dash_force").value
	
	var char: BaseChar = ghost if ghost else unit
	char.backstep(dash_force)
