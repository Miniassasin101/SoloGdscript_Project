class_name BleedEffect extends SpecialEffect

"""
Description:
	The attacker can attempt to cut open a major blood vessel. If the
blow overcomes Armour Points and injures the target, the defender
must make an opposed roll of Endurance against the original attack
roll. If the defender fails, then they begin to bleed profusely. At
the start of each Combat Round the recipient loses one level of Fatigue,
until they collapse and possibly die. Bleeding wounds canbe staunched 
by passing a First Aid skill roll, but the recipient can no longer 
perform any strenuous or violent action without re-opening the wound.


"""

@export var bleed_condition: Condition


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	if event.rolled_damage <= 0:
		Utilities.spawn_text_line(event.unit, "Bleed Failed: No Injury")
		return false
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	var target_unit: Unit = event.target_unit
	var roll: int = Utilities.roll(100)
	var success_level: int = Utilities.check_success_level((target_unit.get_attribute_after_sit_mod("fortitude_skill")), roll)
	
	if event.forced_sp_eff_fail:
		success_level = -3
	
	if success_level >= 1:
		Utilities.spawn_text_line(target_unit, "Bleed Saved", Color.AQUA)
		return
	
	#apply damage effect if the save fails
	apply_effect(event)
	
	# Animation Stand-in


func apply_effect(event: ActivationEvent) -> void:

	var target_unit: Unit = event.target_unit
	

	if target_unit:
		# Make sure to duplicate the resources always to avoid effects applying on every instance
		target_unit.conditions_manager.add_condition(bleed_condition.duplicate()) 

	Utilities.spawn_text_line(target_unit, "Bleeding", Color.FIREBRICK)
