class_name OverextendedCondition extends Condition

# Will tick down at the beginning of every turn, and will block any ability with the "attack" tag.
# Will not tick down the first turn

var is_active: bool = false

func apply(unit: Unit) -> void:
	if !is_active:
		is_active = true
		#return
	
	if condition_level >= 1:
		condition_level -= 1
		Utilities.spawn_text_line(unit, "Overextended", Color.FIREBRICK)
		
	else:
		Utilities.spawn_text_line(unit, "Overextend Cleared", Color.AQUA)
		super.remove_self(unit)


func get_details_text() -> String:
	var details: String = "Overextended Condition Details:"
	details += "\nTurns Left: " + str(condition_level)
	
	# Add the base condition details (like situational modifier if flagged)
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	
	return details
