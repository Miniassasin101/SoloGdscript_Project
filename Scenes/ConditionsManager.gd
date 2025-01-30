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



func book_keeping_check() -> void:
	
	pass



func has_condition(in_name: String) -> bool:
	for condition in conditions:
		if condition.ui_name == in_name:
			return true
	return false

func get_condition_by_name(in_name: String) -> Condition:
	for condition in conditions:
		if condition.ui_name == in_name:
			return condition
	return null
		

func increase_fatigue() -> void:
	var fatigue: FatigueCondition = get_condition_by_name("fatigue") as FatigueCondition
	fatigue.increase_level()
