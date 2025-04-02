class_name BlindOpponentEffect extends SpecialEffect

"""
Description:
	On a critical the defender briefly blinds his opponent by throwing
sand, reflecting sunlight off his shield, or some other tactic which
briefly interferes with the attacker’s vision. The attacker must make
an opposed roll of his Evade skill (or Weapon style if using a shield)
against the defender’s original parry roll. If the attacker fails he 
suffers the Blindness situational modifier for the next 1d3 turns.


"""

@export var blind_condition: Condition


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	# NOTE: Add in a check to see if the target has eyes to begin with?
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	var target_unit: Unit = event.unit
	var roll: int = Utilities.roll(100)
	var success_level: int = Utilities.check_success_level((
		target_unit.get_attribute_after_sit_mod("evade_skill")), roll)
	
	if event.forced_sp_eff_fail:
		success_level = -3
	
	if success_level >= 1:
		Utilities.spawn_text_line(target_unit, "Blind Saved", Color.AQUA)
		return
	
	apply_effect(event)

	
	# Animation Stand-in
	
	# return


func apply_effect(event: ActivationEvent) -> void:

	var target_unit: Unit = event.unit
	

	if target_unit:
		# Make sure to duplicate the resources always to avoid effects applying on every instance
		var new_blind: BlindCondition = blind_condition.duplicate() as BlindCondition
		target_unit.conditions_manager.add_condition(new_blind)
		
		var remaining_rounds: int = new_blind.get_remaining_rounds()
		
		Utilities.spawn_text_line(target_unit, "Blinded %d" % remaining_rounds, Color.GOLD)
