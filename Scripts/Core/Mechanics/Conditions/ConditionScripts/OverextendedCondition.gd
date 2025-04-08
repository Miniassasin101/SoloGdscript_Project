class_name OverextendedCondition extends Condition

# Will tick down at the beginning of every turn and will block any ability with the "attack" tag.
# Will not tick down the first turn.
var is_active: bool = false

func apply(unit: Unit) -> void:
	# On first application, set the active flag.
	if not is_active:
		is_active = true
	# Each turn tick: reduce the condition level.
	if condition_level >= 1:
		condition_level -= 1
		Utilities.spawn_text_line(unit, "Overextended", Color.FIREBRICK)
	else:
		Utilities.spawn_text_line(unit, "Overextend Cleared", Color.AQUA)
		super.remove_self(unit)

# Merge this condition with another OverextendedCondition by adding the remaining turns.
func merge_with(other: Condition) -> void:
	if other is OverextendedCondition:
		# Add the new condition's level (extra turns) to the existing one.
		condition_level += other.condition_level
		is_active = true

# Blocks any attack ability when active.
func blocks_targeting(ability: Ability, _event: ActivationEvent) -> bool:
	if "attack" in ability.tags_type:
		return true
	return false

func get_details_text() -> String:
	var details: String = "Overextended Condition Details:"
	details += "\nTurns Left: " + str(condition_level)
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	return details
