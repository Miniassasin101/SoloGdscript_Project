class_name OutmaneuveredCondition extends Condition



# Instead of a single unit, store an array of outmaneuvering units.
var outmaneuvering_units: Array[Unit] = []

func _init():
	outmaneuvering_units = []
	ui_name = "outmaneuver"

func apply(unit: Unit) -> void:
	# In this design the condition persists until cleared by round-end logic.
	Utilities.spawn_text_line(unit, "Outmaneuvered", Color.FIREBRICK)
	super.remove_self(unit)
	# (Don't remove immediately; wait until conditions naturally expire.)
	# You might add additional tick-down logic here if needed.

# Override the merge_with so that if a new OutmaneuveredCondition is added,
# we simply add its outmaneuvering unit(s) to this condition.
func merge_with(other: Condition) -> void:
	if other is OutmaneuveredCondition:
		for new_unit in (other as OutmaneuveredCondition).outmaneuvering_units:
			if not outmaneuvering_units.has(new_unit):
				outmaneuvering_units.append(new_unit)

func blocks_targeting(ability: Ability, event: ActivationEvent) -> bool:
	# This condition blocks attacking abilities if the target of the attack is one of the units
	# listed in outmaneuvering_units.
	if "attack" in ability.tags_type:
		var target = event.target_unit
		if target != null and target in outmaneuvering_units:
			return true
	return false

func get_details_text() -> String:
	var details: String = "Outmaneuvered Condition Details:"
	if outmaneuvering_units.size() > 0:
		details += "\nCannot attack: "
		for opp in outmaneuvering_units:
			details += opp.ui_name + " "
	details += "\nLasts until end of Round"
	var base = super.get_details_text()
	if base != "":
		details += "\n" + base
	return details
