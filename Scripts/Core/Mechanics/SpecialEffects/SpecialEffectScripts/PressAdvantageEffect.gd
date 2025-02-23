class_name PressAdvantageEffect extends SpecialEffect

"""
Description:
	The attacker pressures his opponent, so that his foe is forced to
remain on the defensive, and cannot attack on their next turn. This
allows the attacker to potentially establish an unbroken sequence
of attacks whilst the defender desperately blocks. It is only effective
against foes concerned with defending themselves. Foes that find
themselves constantly locked under an unceasing sequence of Press
Advantage will likely disengage from the combat, call for help, or use
Prepare Counter to give attackers a nasty surprise.

"""

# Unlike overextended, the "under_pressure" condition cannot stack
@export var under_pressure_condition: Condition


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

	if target_unit:
		target_unit.conditions_manager.add_condition(under_pressure_condition.duplicate()) 

	Utilities.spawn_text_line(target_unit, "Under Pressure", Color.FIREBRICK)
