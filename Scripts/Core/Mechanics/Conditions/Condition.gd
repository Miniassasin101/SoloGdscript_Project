class_name Condition extends Resource

## Internal name for the condition, Always use snakecase.
@export var ui_name: String = "n/a"

@export var condition_level: int = 0

# This is the interval at which the condition applies.
# Is checked to see if it applies once a turn, round, cycle, day, ect.
# Never doesnt mean it cant apply, just that it wont do so unprompted.
enum ApplicationInterval {Never, PerRound, PerTurn, PerModify, PerAttackEnd}
@export var application_interval: ApplicationInterval = ApplicationInterval.Never

@export var tags_type: Array[StringName] = []

## The types of abilities that this condition blocks while on a character, Ex: "attack" or "move"
@export var blocking_tags: Array[StringName] = []


@export var is_situational_modifier: bool = false
@export_enum("VERY_EASY", "EASY", "STANDARD", "HARD", "FORMIDABLE", "HERCULEAN", "HOPELESS") var situational_modifier = 2



func can_apply(_unit: Unit) -> bool:
	
	
	
	return true

func apply(_unit: Unit) -> void:
	pass

func can_modify(_condition: Condition) -> bool:
	return false  # By default, conditions do not modify others.

func modify(_condition: Condition) -> void:
	pass  # Override in specific conditions.

func increase_level(_unit: Unit, by_amount: int = 1) -> void:
	condition_level += by_amount

func get_situational_modifier() -> int:
	return situational_modifier

func get_details_text() -> String:
	var details := ""
	
	if is_situational_modifier:
		details += "Situational Modifier: %s" % _map_modifier_to_text(get_situational_modifier())

	return details

func _map_modifier_to_text(mod: int) -> String:
	match mod:
		0: return "VERY_EASY"
		1: return "EASY"
		2: return "STANDARD"
		3: return "HARD"
		4: return "FORMIDABLE"
		5: return "HERCULEAN"
		6: return "HOPELESS"
		_: return "UNKNOWN"

func merge_with(other: Condition) -> void:
	# Default implementation: no merging.
	pass

func remove_self(unit: Unit) -> void:
	unit.conditions_manager.remove_condition(self)


# New virtual function to determine if this condition blocks targeting from the given ability and attacker.
func blocks_targeting(ability: Ability, event: ActivationEvent) -> bool:
	# By default, no condition blocks targeting.
	return false
