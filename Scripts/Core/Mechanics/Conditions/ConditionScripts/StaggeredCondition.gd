class_name StaggeredCondition extends Condition

# Adds a penalty to attacking and parrying, and is harder to remove when adjacent to an enemy



func _init() -> void:
	pass


func apply(unit: Unit) -> void:
	Utilities.spawn_text_line(unit, "Staggered", Color.FIREBRICK)
	

	
func get_details_text() -> String:
	var details: String = "Staggered Condition Details:"
	details += "\n Removed through Regain Footing action or Steady special effect"
	
	# Add the base condition details (like situational modifier if flagged)
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	
	return details
