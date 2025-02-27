extends Condition
class_name BracingCondition

@export var knockback_multiplier: float = 0.5

@export var remove_on_modify: bool = false

func can_modify(condition: Condition) -> bool:
	return condition is KnockbackCondition

func modify(condition: Condition) -> void:
	if condition is KnockbackCondition:
		condition.knockback_distance = max(0, floor(condition.knockback_distance * knockback_multiplier))


func apply(_unit: Unit) -> void:
	Utilities.spawn_text_line(_unit, "Braced", Color.AQUA)
	remove_self(_unit)
