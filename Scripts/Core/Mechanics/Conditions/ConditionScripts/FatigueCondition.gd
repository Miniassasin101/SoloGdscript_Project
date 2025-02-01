class_name FatigueCondition extends Condition

# Fatigue levels with their names and associated penalties
const FATIGUE_LEVELS: Array[Dictionary] = [
	{"name": "Fresh", "skill_grade": "No Penalties"},
	{"name": "Winded", "skill_grade": "Hard", "recovery_period": "15 minutes"},
	{"name": "Tired", "skill_grade": "Hard", "movement_penalty": 1, "recovery_period": "3 hours"},
	{"name": "Wearied", "skill_grade": "Formidable", "movement_penalty": 2, "initiative_penalty": -2, "recovery_period": "6 hours"},
	{"name": "Exhausted", "skill_grade": "Formidable", "movement_penalty": "Halved", "initiative_penalty": -4, "action_points_penalty": -1, "recovery_period": "12 hours"},
	{"name": "Debilitated", "skill_grade": "Herculean", "movement_penalty": "Halved", "initiative_penalty": -6, "action_points_penalty": -2, "recovery_period": "18 hours"},
	{"name": "Incapacitated", "skill_grade": "Herculean", "movement_penalty": "Immobile", "initiative_penalty": -8, "action_points_penalty": -3, "recovery_period": "24 hours"},
	{"name": "Semi-Conscious", "skill_grade": "Hopeless", "recovery_period": "36 hours", "activity": "No Activities Possible"},
	{"name": "Comatose", "skill_grade": "No Activities Possible", "recovery_period": "48 hours", "activity": "No Activities Possible"},
	{"name": "Dead", "skill_grade": "Dead", "recovery_period": "Never"}
]

func get_fatigue_level_name() -> String:
	# Get the fatigue level name based on the condition level
	if condition_level < 0 or condition_level >= FATIGUE_LEVELS.size():
		return "Unknown Fatigue Level"
	return FATIGUE_LEVELS[condition_level]["name"]

func get_fatigue_details() -> Dictionary:
	# Return all details for the current fatigue level
	if condition_level < 0 or condition_level >= FATIGUE_LEVELS.size():
		return {"name": "Unknown", "details": "No details available"}
	return FATIGUE_LEVELS[condition_level]

func increase_level(unit: Unit, by_amount: int = 1) -> void:
	super.increase_level(unit, by_amount)

	var new_fatigue_level_ui_name: String = get_fatigue_level_name()
	Utilities.spawn_text_line(unit, new_fatigue_level_ui_name)


func get_situational_modifier() -> int:
	if condition_level < 0 or condition_level >= FATIGUE_LEVELS.size():
		return Utilities.DIFFICULTY_GRADE.STANDARD  # Default to STANDARD if out of bounds
	
	var fatigue_data = FATIGUE_LEVELS[condition_level]
	if "skill_grade" in fatigue_data:
		var normalized_grade = fatigue_data["skill_grade"].to_upper()  # Convert to uppercase for normalization
		match normalized_grade:
			"VERY_EASY": return Utilities.DIFFICULTY_GRADE.VERY_EASY
			"EASY": return Utilities.DIFFICULTY_GRADE.EASY
			"STANDARD": return Utilities.DIFFICULTY_GRADE.STANDARD
			"HARD": return Utilities.DIFFICULTY_GRADE.HARD
			"FORMIDABLE": return Utilities.DIFFICULTY_GRADE.FORMIDABLE
			"HERCULEAN": return Utilities.DIFFICULTY_GRADE.HERCULEAN
			"HOPELESS": return Utilities.DIFFICULTY_GRADE.HOPELESS
	return Utilities.DIFFICULTY_GRADE.STANDARD  # Default if no match




func get_initiative_penalty() -> int:
	if condition_level < 0 or condition_level >= FATIGUE_LEVELS.size():
		return 0  # No penalty for invalid levels

	var fatigue_data = FATIGUE_LEVELS[condition_level]
	if "initiative_penalty" in fatigue_data:
		return fatigue_data["initiative_penalty"]
	return 0  # No penalty for this level
