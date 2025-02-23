class_name OverextendOpponentEffect extends SpecialEffect

"""
Description:
	The defender sidesteps or retreats at an inconvenient moment, 
	causing the attacker to overreach himself. Opponent cannot 
	attack on his next turn. This special effect can be stacked.

"""

@export var overextended_condition: Condition


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	apply_effect(event)
	
	# Animation Stand-in



func apply_effect(event: ActivationEvent) -> void:
	var target_unit: Unit = event.unit

	if target_unit:
		if target_unit.conditions_manager.has_condition_by_condition(overextended_condition):
			target_unit.conditions_manager.increase_condition_level_by_condition(overextended_condition)
		else:
			# Make sure to duplicate the resources always to avoid effects applying on every instance
			target_unit.conditions_manager.add_condition(overextended_condition.duplicate()) 

	Utilities.spawn_text_line(target_unit, "Overextended", Color.FIREBRICK)
