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

func book_keeping_check() -> void:
	
	pass

func add_condition(condition: Condition) -> void:
	if condition != null:
		if !has_condition_by_condition(condition):
			conditions.append(condition)


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
