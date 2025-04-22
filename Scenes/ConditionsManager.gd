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
			if condition.can_apply(unit):
				condition.apply(unit)

func apply_conditions_turn_interval() -> void:
	for condition in conditions:
		if condition.application_interval == Condition.ApplicationInterval.PerTurn:
			if condition.can_apply(unit):
				condition.apply(unit)

func apply_conditions_attack_declared_interval() -> void:
	for condition in conditions:
		if condition.application_interval == Condition.ApplicationInterval.PerAttackDeclared:
			if condition.can_apply(unit):
				condition.apply(unit)

func apply_conditions_attack_end_interval() -> void:
	for condition in conditions:
		if condition.application_interval == Condition.ApplicationInterval.PerAttackEnd:
			if condition.can_apply(unit):
				condition.apply(unit)

func apply_condition_by_name(condition_name: String) -> void:
	for condition in conditions:
		if condition.ui_name == condition_name:
			if condition.can_apply(unit):
				condition.apply(unit)
				return

func apply_condition_by_condition(condition: Condition) -> void:
	for cond in conditions:
		if condition == cond:
			if cond.can_apply(unit):
				condition.apply(unit)
				return

func apply_situational_modifier(attribute_value: int) -> int:
	var highest_difficulty = Utilities.DIFFICULTY_GRADE.STANDARD  # Default grade
	
	# Find the highest situational modifier from conditions
	for condition in conditions:
		if condition.is_situational_modifier:
			var condition_modifier = condition.get_situational_modifier() as Utilities.DIFFICULTY_GRADE
			if condition_modifier > highest_difficulty:
				highest_difficulty = condition_modifier
	
	# Apply the highest difficulty multiplier
	var multiplier = Utilities.DIFFICULTY_GRADE_MULTIPLIER[Utilities.DIFFICULTY_GRADE.keys()[highest_difficulty]]
	return ceil(attribute_value * multiplier)  # Rounds up the final value

func get_highest_situational_modifier(sit_mod_change: int = 0) -> float:
	var highest_difficulty = Utilities.DIFFICULTY_GRADE.STANDARD  # Default is STANDARD
	
	# Iterate through all conditions to find the highest situational modifier
	for condition in conditions:
		if condition.is_situational_modifier:
			var condition_modifier = condition.get_situational_modifier() as Utilities.DIFFICULTY_GRADE
			if condition_modifier > highest_difficulty:
				highest_difficulty = condition_modifier
	
	# FIXME: The sit mod change can bring outside the bounds of the multiplier dictionary
	# Directly use the highest_difficulty enum as the key for the dictionary
	var diff_mod: float = Utilities.DIFFICULTY_GRADE_MULTIPLIER[highest_difficulty + sit_mod_change]
	return diff_mod


func get_highest_situational_modifier_name(sit_mod_change: int = 0) -> String:
	var highest_difficulty: int = Utilities.DIFFICULTY_GRADE.STANDARD
	
	for condition in conditions:
		if condition.is_situational_modifier:
			var condition_modifier = condition.get_situational_modifier()
			if condition_modifier > highest_difficulty:
				highest_difficulty = condition_modifier
	
	var adjusted_difficulty: int = clampi(highest_difficulty + sit_mod_change, 0, Utilities.DIFFICULTY_GRADE.size() - 1)
	return Utilities.DIFFICULTY_GRADE.keys()[adjusted_difficulty]




func book_keeping_check() -> void:
	
	pass


func can_use_ability_given_conditions(ability: Ability) -> bool:
	var blocked_ability_types: Array[StringName] = []
	for condition in conditions:
		blocked_ability_types.append_array(condition.blocking_tags)
	for block in blocked_ability_types:
		if ability.tags_type.has(block):
			return false
	return true

func can_add_condition_given_conditions(condition: Condition) -> bool:
	var blocked_condition_types: Array[StringName] = []
	for cond in conditions:
		blocked_condition_types.append_array(condition.blocking_tags)
	for block in blocked_condition_types:
		if condition.tags_type.has(block):
			return false
	return true

func modify_condition_given_conditions(condition: Condition) -> void:
	for existing_condition in conditions:
		if existing_condition.can_modify(condition):
			existing_condition.modify(condition)
			if existing_condition.application_interval == Condition.ApplicationInterval.PerModify:
				if existing_condition.can_apply(unit):
					existing_condition.apply(unit)

func add_condition(condition: Condition) -> bool:
	if condition != null:
		# Look for an existing condition with the same identifier (for example, ui_name).
		var existing = get_condition_by_name(condition.ui_name)
		if existing:
			# Let the existing condition handle merging.
			existing.merge_with(condition)
			return true
		else:
			# Allow existing conditions to modify the new condition.
			modify_condition_given_conditions(condition)
			conditions.append(condition)
			return true
	return false



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

func increase_condition_level_by_condition(condition: Condition, by_amount: int = 1) -> void:
	for cond in conditions:
		if condition.ui_name == cond.ui_name:
			cond.increase_level(unit, by_amount)
			return

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
