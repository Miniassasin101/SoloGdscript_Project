class_name UnderPressureCondition extends Condition

# Will tick down at the beginning of every turn, and will block any ability with the "attack" tag.
# Will not tick down the first turn
# Is caused by the Press Advantage special effect

var is_active: bool = false

func apply(unit: Unit) -> void:
	if !is_active:
		is_active = true
		#return
	
	if condition_level >= 1:
		condition_level -= 1
		Utilities.spawn_text_line(unit, "Under Pressure", Color.FIREBRICK)
		
	else:
		Utilities.spawn_text_line(unit, "Pressure Cleared", Color.AQUA)
		super.remove_self(unit)
