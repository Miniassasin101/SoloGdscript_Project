@tool
class_name RegainFootingAbility extends Ability

@export_group("Attributes")
@export var ap_cost: int = 1

var event: ActivationEvent = null
var unit: Unit = null



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	unit = event.unit
	if not unit or not event.target_grid_position:
		push_error("BraceAbility: Missing unit or target grid position.")
		end_ability(event)
		return
	
	
	
	remove_stagger()
	
	# NOTE: Add an animation here to show that the unit is getting up
	

	
	if can_end(event):
		event.successful = true
		end_ability(event)



func remove_stagger() -> void:

	
	var condition_name: String = "staggered"
	
	if unit:
		var prone_cond: Condition = unit.conditions_manager.get_condition_by_name(condition_name)
		if prone_cond == null:
			Console.print_error("Condition '" + prone_cond.ui_name.to_pascal_case() + "' not found on unit '" + unit.ui_name + "'.")
			return
	
		# Remove the condition.
		Utilities.spawn_text_line(unit, "Stagger Cleared", Color.AQUA)
		unit.conditions_manager.remove_condition(prone_cond)
		







func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	
	if !_event.unit.conditions_manager.has_condition("staggered"):
		return false
	
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	
	return false



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.unit
	var valid_positions: Array[GridPosition] = []
	
	valid_positions.append(in_unit.get_grid_position())
	
	return valid_positions

# --- Utility Functions --- 
