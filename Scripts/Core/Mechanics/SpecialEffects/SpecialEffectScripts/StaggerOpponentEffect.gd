class_name StaggerOpponentEffect extends SpecialEffect

"""
Description:
	The character attempts to knock his opponent off-balance or 
break their stance. The opponent must make an opposed roll of his Brawn,
Evade or Acrobatics against the character’s original roll. If the target
fails, he becomes staggered. Quadruped opponents (or creatures with even
more legs) may substitute their Athletics skill for Evade, and treat the
roll as one difficulty grade easier


"""

@export var staggered_condition: Condition


func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	# NOTE: Add in a check to see if the target has eyes to begin with?
	
	return true




# NOTE: maybe switch to event instead
func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	var target_unit: Unit = event.target_unit
	var roll: int = Utilities.roll(100)
	var success_level: int = Utilities.check_success_level((
		target_unit.get_attribute_after_sit_mod("evade_skill")), roll)
	
	if event.forced_sp_eff_fail:
		success_level = -3
	
	if success_level >= 1:
		Utilities.spawn_text_line(target_unit, "Stagger Saved", Color.AQUA)
		return
	
	apply_effect(event)

	
	# Animation Stand-in
	
	# return


func apply_effect(event: ActivationEvent) -> void:

	var target_unit: Unit = event.target_unit
	

	if target_unit:
		# Make sure to duplicate the resources always to avoid effects applying on every instance
		var new_stagger: StaggeredCondition = staggered_condition.duplicate() as StaggeredCondition
		target_unit.conditions_manager.add_condition(new_stagger)
	
		
		Utilities.spawn_text_line(target_unit, "Staggered", Color.FIREBRICK)
