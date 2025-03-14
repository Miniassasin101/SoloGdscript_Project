class_name BleedingCondition extends Condition

# If the Bleeding Condition is patched up, it doesnt apply the effect, but check to see if the
# Unit does strenuous physical activity like make an attack. If so, patched up becomes false, and
# the visual effect of the wound reopening begins

var patched_up: bool = false

var fatigue_lost_to_bleed: int = 0


func apply(unit: Unit) -> void:
	if patched_up:
		return
	
	var conditions_manager: ConditionsManager = unit.conditions_manager

	if conditions_manager.has_condition("fatigue"):
		conditions_manager.increase_fatigue()
		fatigue_lost_to_bleed += 1
		Utilities.spawn_text_line(unit, "Bleeding", Color.FIREBRICK)
	
