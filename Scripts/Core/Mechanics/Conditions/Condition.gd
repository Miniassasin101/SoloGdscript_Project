class_name Condition extends Resource


@export var ui_name: String

@export var condition_level: int = 0

# This is the interval at which the condition applies.
# Is checked to see if it applies once a turn, round, cycle, day, ect.
# Never doesnt mean it cant apply, just that it wont do so unprompted.
enum ApplicationInterval {Never, PerRound}
@export var application_interval: ApplicationInterval = ApplicationInterval.Never
@export var is_situational_modifier: bool = false
@export_enum("VERY_EASY", "EASY", "STANDARD", "HARD", "FORMIDABLE", "HERCULEAN", "HOPELESS") var situational_modifier = 2



func can_apply() -> bool:
	
	return true

func apply(unit: Unit) -> void:
	pass

func increase_level(unit: Unit, by_amount: int = 1) -> void:
	condition_level += by_amount

func get_situational_modifier() -> int:
	return situational_modifier
