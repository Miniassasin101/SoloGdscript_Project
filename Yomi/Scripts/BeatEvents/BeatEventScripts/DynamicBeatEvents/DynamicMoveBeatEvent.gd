class_name DynamicMoveBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var move_force: float = get_beat_value_by_name("move_force").value
	
	var char: BaseChar = ghost if ghost else unit
	
	var for_dir := char.floor_normal.cross(-char.global_basis.x)
	
	
	
	char.move_in_direction(for_dir, move_force)
	
