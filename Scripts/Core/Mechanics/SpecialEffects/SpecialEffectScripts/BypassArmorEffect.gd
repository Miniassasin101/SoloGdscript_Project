class_name BypassArmorEffect extends SpecialEffect

"""
Description:
	On a critical the attacker finds a gap in the defender’s natural or
worn armour. If the defender is wearing armour above natural protection, then the attacker must decide which of the two is bypassed.
This effect can be stacked to bypass both. For the purposes of this
effect, physical protection gained from magic is considered as being
worn armour.

This only can be activated by an attacking unit if the attacking unit 
scores a critical on their attack (2 success level)
"""


func can_activate(event: ActivationEvent) -> bool:
	if !super.can_activate(event):
		return false
	
	if !event.target_unit.body.get_if_any_part_has_armor():
		return false
	
	# FIXME: Later add ability to choose which layer of armor is bypassed and pass the value
	
	return true



func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	return true



# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	event.bypass_armor = true
