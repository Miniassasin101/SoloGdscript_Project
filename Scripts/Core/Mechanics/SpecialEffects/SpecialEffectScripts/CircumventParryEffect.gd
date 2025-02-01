class_name CircumventParryEffect extends SpecialEffect

"""
Description:
	On a critical the attacker may completely bypass an otherwise successful parry.

This only can be activated by an attacking unit if the attacking unit 
scores a critical on their attack (2 success level)
"""


func can_activate(event: ActivationEvent) -> bool:
	if !event.parry_successful:
		return false
	
	if !super.can_activate(event):
		return false
	
	
	
	
	return true



func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	return true



# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	event.parry_successful = false
	
	Utilities.spawn_text_line(event.target_unit, "Parry Circumvented", Color.FIREBRICK)
