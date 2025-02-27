@tool
class_name BraceAbility extends Ability

@export_group("Attributes")
@export var ap_cost: int = 1

@export var bracing_condition: BracingCondition

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
	
	# Validate the chosen target position.
	if not can_activate(event):
		push_error("BraceAbility: Target grid position is invalid.")
		end_ability(event)
		return
	
	# NOTE: Add an animation here to show that the unit is bracing
	
	apply_effect()
	
	

	
	if can_end(event):
		event.successful = true
		end_ability(event)



func apply_effect() -> void:
	var target_unit: Unit = event.unit
	
	var bracing_cond: BracingCondition = bracing_condition.duplicate()
	
	
	if target_unit:
		if target_unit.conditions_manager.add_condition(bracing_cond):
			SignalBus.unit_moved_position.connect(target_unit.conditions_manager.remove_condition.bind(bracing_cond))
			Utilities.spawn_text_line(target_unit, "Bracing", Color.ALICE_BLUE)







func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
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
