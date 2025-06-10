class_name DynamicMoveBeatEvent
extends DynamicBeatEvent


func on_beat_event(state: State) -> void:
	super.on_beat_event(state)
	
	var move_force: float = get_beat_value_by_name("move_force").value
	
	var for_dir := unit.floor_normal.cross(-unit.global_basis.x)
	unit.move_in_direction(for_dir, move_force)
