class_name BlindCondition extends Condition

# If the Bleeding Condition is patched up, it doesnt apply the effect, but check to see if the
# Unit does strenuous physical activity like make an attack. If so, patched up becomes false, and
# the visual effect of the wound reopening begins


var remaining_rounds: int = 1

func _init() -> void:
	remaining_rounds = Utilities.roll(3)


func get_remaining_rounds() -> int:
	return remaining_rounds

func apply(unit: Unit) -> void:
	if remaining_rounds >= 1:
		remaining_rounds -= 1
		Utilities.spawn_text_line(unit, "Blinded", Color.GOLD)
		
	else:
		Utilities.spawn_text_line(unit, "Blind Cleared", Color.AQUA)
		super.remove_self(unit)
	
func get_details_text() -> String:
	var details: String = "Blinded for %d more round(s)." % remaining_rounds
	
	# Add the base condition details (like situational modifier if flagged)
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	
	return details
