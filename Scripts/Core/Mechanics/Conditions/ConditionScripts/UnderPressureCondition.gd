class_name UnderPressureCondition extends Condition

# Will tick down at the beginning of every turn and will block any ability with the "attack" tag.
# Will not tick down the first turn; caused by the Press Advantage special effect.
var is_active: bool = false

func apply(unit: Unit) -> void:
	if not is_active:
		is_active = true
	if condition_level >= 1:
		condition_level -= 1
		Utilities.spawn_text_line(unit, "Under Pressure", Color.FIREBRICK)
	else:
		Utilities.spawn_text_line(unit, "Pressure Cleared", Color.AQUA)
		super.remove_self(unit)

# Merge another UnderPressureCondition by adding its remaining turns.
func merge_with(other: Condition) -> void:
	if other is UnderPressureCondition:
		condition_level += other.condition_level
		is_active = true

# Blocks any attack ability when active.
func blocks_targeting(ability: Ability, _event: ActivationEvent) -> bool:
	if "attack" in ability.tags_type:
		return true
	return false

func get_details_text() -> String:
	var details: String = "Under Pressure Condition Details:"
	details += "\nTurns Left: " + str(condition_level)
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	return details
