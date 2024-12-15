## Global Autoload Singleton
## Manages any utilities and calculations for the ability system
extends Node

func get_ability_from_container():
	pass

func get_ability_from_unit():
	pass

func check_success_level(skill: int, roll: int) -> int:
	# Check for critical failure
	if roll == 99 or roll == 100:
		return -1
	
	# Check for critical success
	if roll <= ceil(skill * 0.1):  # 10% of skill value rounded up
		return 2
	
	# Check for regular success
	if roll <= skill:
		return 1
	
	# Otherwise, it's a failure
	return 0


## This function recieves a die type (Ex: 20 for a d20) and the number that need to be rolled, returns the sum of the results.
func roll(die_type: int = 100, count: int = 1) -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var total = 0
	for i in range(count):
		total += rng.randi_range(1, die_type)
	return total

## Calculation logic based on `calculation_type`. A value of '-1' represents an error.
func calculate(derived_from: Array[String], calculation_type: int, specs: Dictionary) -> int:
	match calculation_type:
		0:
			# Push an error and return null for base attributes
			push_error("Tried to calculate on a base attribute. Calculation type 0 is invalid.")
			return -1
		1:
			# Add up all the values of the keys in `derived_from` found in `specs`
			var total = 0
			for key in derived_from:
				if specs.has(key):
					total += int(specs[key])
				else:
					push_error("Key '%s' in derived_from not found in specs dictionary." % key)
			return total
		2:
			# Placeholder: Look up a table and derive the value
			# For now, just push a warning and return 0 as a placeholder value
			push_warning("Placeholder: Table lookup not yet implemented for calculation type 2.")
			return -1
		_:
			# Handle unexpected calculation types
			push_error("Invalid calculation type: %d" % calculation_type)
			return -1

func lookup_table_value(derived_from: Array[StringName], table: Dictionary, specs: Dictionary) -> int:
	# Example logic for cross-referencing
	var key = ""
	for attr in derived_from:
		key += str(specs[attr].current_value) + "-"
	key = key.rstrip("-")
	if table.has(key):
		return table[key]
	else:
		push_error("Key '%s' not found in lookup table." % key)
		return -1
