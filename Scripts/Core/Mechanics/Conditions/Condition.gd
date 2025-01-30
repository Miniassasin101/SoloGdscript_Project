class_name Condition extends Resource


@export var ui_name: String

@export var condition_level: int = 0
#@export var skill_grade: 


func can_apply() -> void:
	pass
	
func increase_level(by_amount: int = 1) -> void:
	condition_level += by_amount
