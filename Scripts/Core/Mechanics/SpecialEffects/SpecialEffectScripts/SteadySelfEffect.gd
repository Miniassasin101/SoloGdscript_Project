# SteadySelfEffect.gd
extends SpecialEffect
class_name SteadySelfEffect

"""
Description:
	The winning unit steadies themselves, regaining their balance and 
	removing the staggered condition.
"""



func can_activate(event: ActivationEvent) -> bool:

	if !super.can_activate(event):
		return false
	
	return event.unit.conditions_manager.has_condition("staggered")


func can_apply(event: ActivationEvent) -> bool:
	if not super.can_apply(event):
		return false
	# only if the unit actually has "staggered"
	return event.unit.conditions_manager.has_condition("staggered")

func apply(event: ActivationEvent) -> void:
	super.apply(event)
	_remove_stagger(event)
	

func _remove_stagger(event: ActivationEvent) -> void:
	var unit: Unit = event.winning_unit
	var cond: Condition = unit.conditions_manager.get_condition_by_name("staggered")
	if cond:
		unit.conditions_manager.remove_condition(cond)
		Utilities.spawn_text_line(unit, "Steady Self", Color.AQUA)
	else:
		# should never happen because can_apply checked, but just in case
		Console.print_error("SteadySelfEffect: no staggered condition on " + unit.ui_name, true)
