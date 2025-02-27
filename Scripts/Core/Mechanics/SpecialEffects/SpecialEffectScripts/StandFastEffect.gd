class_name StandFastEffect extends SpecialEffect

"""
Description:
	The defender braces himself against the force of an attack, allowing
them to avoid the Knockback effects of any damage received.

"""

# Unlike overextended, the "under_pressure" condition cannot stack
@export var bracing_condition: Condition


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
	var target_unit: Unit = event.target_unit
	
	var bracing_cond: BracingCondition = bracing_condition.duplicate()
	
	bracing_cond.remove_on_modify = true
	
	if target_unit:
		target_unit.conditions_manager.add_condition(bracing_cond) 

	Utilities.spawn_text_line(target_unit, "Under Pressure", Color.FIREBRICK)
