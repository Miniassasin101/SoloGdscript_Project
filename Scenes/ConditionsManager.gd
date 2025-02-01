class_name ConditionsManager extends Node

@export var unit: Unit

@export var conditions: Array[Condition]


func _ready() -> void:
	duplicate_conditions()



func duplicate_conditions() -> void:
	var temp_conditions: Array[Condition] = []
	for condition in conditions:
		temp_conditions.append(condition.duplicate())
	conditions = temp_conditions

func apply_conditions_round_interval() -> void:
	for condition in conditions:
		if condition.application_interval == Condition.ApplicationInterval.PerRound:
			if condition.can_apply():
				condition.apply(unit)


func apply_situational_modifier(attribute_value: int) -> int:
	var highest_difficulty = Utilities.DIFFICULTY_GRADE.STANDARD  # Default grade
	
	# Find the highest situational modifier from conditions
	for condition in conditions:
		if condition.is_situational_modifier:
			var condition_modifier = condition.get_situational_modifier()
			if condition_modifier > highest_difficulty:
				highest_difficulty = condition_modifier
	
	# Apply the highest difficulty multiplier
	var multiplier = Utilities.DIFFICULTY_GRADE_MULTIPLIER[Utilities.DIFFICULTY_GRADE.keys()[highest_difficulty]]
	return ceil(attribute_value * multiplier)  # Rounds up the final value

func get_highest_situational_modifier() -> float:
	var highest_difficulty = Utilities.DIFFICULTY_GRADE.STANDARD  # Default is STANDARD
	
	# Iterate through all conditions to find the highest situational modifier
	for condition in conditions:
		if condition.is_situational_modifier:
			var condition_modifier = condition.get_situational_modifier()
			if condition_modifier > highest_difficulty:
				highest_difficulty = condition_modifier

	# Directly use the highest_difficulty enum as the key for the dictionary
	var diff_mod: float = Utilities.DIFFICULTY_GRADE_MULTIPLIER[highest_difficulty]
	return Utilities.DIFFICULTY_GRADE_MULTIPLIER[highest_difficulty]



func book_keeping_check() -> void:
	
	pass

func add_condition(condition: Condition) -> void:
	if condition != null:
		if !has_condition_by_condition(condition):
			conditions.append(condition)

func remove_condition(condition: Condition) -> void:
	if has_condition_by_condition(condition):
		conditions.erase(condition)

func has_condition(in_name: String) -> bool:
	for condition in conditions:
		if condition.ui_name == in_name:
			return true
	return false

func has_condition_by_condition(condition: Condition) -> bool:
	for cond in conditions:
		if condition.ui_name == cond.ui_name:
			return true
	return false

func get_all_conditions() -> Array[Condition]:
	return conditions

func get_condition_by_name(in_name: String) -> Condition:
	for condition in conditions:
		if condition.ui_name == in_name:
			return condition
	return null
		

func increase_fatigue(by_amount: int = 1) -> void:
	var fatigue: FatigueCondition = get_condition_by_name("fatigue") as FatigueCondition
	fatigue.increase_level(unit, by_amount)


func get_total_initiative_penalty() -> int:
	var total_penalty = 0
	for condition in conditions:
		if condition is FatigueCondition:
			total_penalty += (condition as FatigueCondition).get_initiative_penalty()
	return total_penalty

func get_total_penalty(penalty_type: String) -> float:
	var total_penalty: float = 0.0
	for condition in conditions:
		if condition is FatigueCondition:  # Check if the condition is FatigueCondition
			var fatigue_data = (condition as FatigueCondition).get_fatigue_details()
			if penalty_type in fatigue_data:  # Check if the penalty exists in the fatigue data
				var penalty = fatigue_data[penalty_type]
				
				# Handle special cases like "Halved" or "Immobile"
				if typeof(penalty) == TYPE_FLOAT or typeof(penalty) == TYPE_INT: 
					total_penalty += penalty  # Sum numeric penalties
				elif penalty == "Halved":
					return -0.5  # Use -0.5 as a halving multiplier
				elif penalty == "Immobile":
					return -1.0  # Completely restrict movement

	return total_penalty
