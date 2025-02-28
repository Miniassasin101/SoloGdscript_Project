class_name FacingPenaltyCondition extends Condition

# Applies a temporary penalty to a unit if they are trying to parry or attack
# from a tile their weapon cant easily reach

func apply(unit: Unit) -> void:
	remove_self(unit)
