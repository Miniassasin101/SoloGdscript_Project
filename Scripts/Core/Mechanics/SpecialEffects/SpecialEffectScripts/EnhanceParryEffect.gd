class_name EnhanceParryEffect extends SpecialEffect

"""
Description:
	On a critical the defender manages to deflect the entire force of an
attack, no matter the Size of his weapon.

This only can be activated by an defending unit if the defending unit 
scores a critical on their parry (2 success level)
"""


func can_activate(event: ActivationEvent) -> bool:

	if !super.can_activate(event):
		return false
	
	if !event.parry_successful:
		return false
	
	var defender_weapon: Weapon = event.target_unit.get_equipped_weapon()
	var attacker_weapon: Weapon = event.unit.get_equipped_weapon()
	
	if defender_weapon.size >= attacker_weapon.size:
		return false
	
	return true



func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	return true



func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	event.enhance_parry = true
	
	Utilities.spawn_text_line(event.winning_unit, "Parry Enhanced", Color.AQUA)
