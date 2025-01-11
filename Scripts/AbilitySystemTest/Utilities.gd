## Global Autoload Singleton
## Manages any utilities and calculations for the ability system
extends Node

enum MovementGait {
	HOLD_GROUND,
	WALK,
	RUN,
	SPRINT
}

# Speed multipliers for each gait (times the unit’s base movement rate).
const GAIT_SPEED_MULTIPLIER = {
	MovementGait.HOLD_GROUND: 0,
	MovementGait.WALK: 1.0,
	MovementGait.RUN: 3.0,
	MovementGait.SPRINT: 5.0
}

# Allowed actions for each gait 
# (strings here are just examples; adapt them to your actual action names)
const GAIT_ALLOWED_ACTIONS = {
	MovementGait.HOLD_GROUND: ["Attack", "Cast Magic", "Delay", "Dither", "Evade", "Interrupt", "Parry", "Ready Weapon", "Ward Location"],
	MovementGait.WALK: ["Attack (ranged only)", "Cast Magic (ranged only)", "Delay", "Dither", "Evade", "Interrupt", "Parry", "Ready Weapon", "Ward Location"],
	MovementGait.RUN: ["Dither", "Ward Location", "Evade"],
	MovementGait.SPRINT: ["Dither"]
}


func get_ability_from_container():
	pass

func get_ability_from_unit():
	pass

func get_front_tiles(unit: Unit) -> Array[GridPosition]:
	var facing: int = unit.facing
	var front_tiles: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	# Get the grid positions of the three front tiles based on the facing direction
	match facing:
		0:  # Facing North
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Right front
		1:  # Facing East
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Right front
		2:  # Facing South
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Right front
		3:  # Facing West
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Right front

	return front_tiles.filter(func(gridpos: GridPosition): return gridpos != null)  # Remove null values


func get_side_tiles(unit: Unit) -> Array[GridPosition]:
	var facing = unit.facing
	var side_tiles = []
	var grid_position = unit.grid_position

	# Get the grid positions of the side tiles based on the facing direction
	match facing:
		0:  # Facing North
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))  # Left
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))  # Right
		1:  # Facing East
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))  # Left
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))  # Right
		2:  # Facing South
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))  # Left
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))  # Right
		3:  # Facing West
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))  # Left
			side_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))  # Right

	return side_tiles.filter(func(gridpos): return gridpos != null) # Remove null values


func get_back_tiles(unit: Unit) -> Array[GridPosition]:
	var facing: int = unit.facing
	var back_tiles: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	# Get the grid positions of the three back tiles based on the facing direction
	match facing:
		0:  # Facing North
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Left back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))      # Center back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Right back
		1:  # Facing East
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Left back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))      # Center back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Right back
		2:  # Facing South
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Left back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))      # Center back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Right back
		3:  # Facing West
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Left back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))      # Center back
			back_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Right back

	return back_tiles.filter(func(gridpos: GridPosition): return gridpos != null)  # Remove null values


func get_right_side_tile(unit: Unit) -> GridPosition:
	var facing = unit.facing
	var grid_position = unit.grid_position

	# Get the grid position of the right side tile based on the facing direction
	match facing:
		0:  # Facing North
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z)
		1:  # Facing East
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1)
		2:  # Facing South
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z)
		3:  # Facing West
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1)

	return null


func get_left_side_tile(unit: Unit) -> GridPosition:
	var facing = unit.facing
	var grid_position = unit.grid_position

	# Get the grid position of the left side tile based on the facing direction
	match facing:
		0:  # Facing North
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z)
		1:  # Facing East
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1)
		2:  # Facing South
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z)
		3:  # Facing West
			return LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1)

	return null



func check_success_level(skill: int, in_roll: int) -> int:
	# Check for critical failure
	if in_roll == 99 or in_roll == 100:
		return -1
	
	# Check for critical success
	if in_roll <= ceil(skill * 0.1):  # 10% of skill value rounded up
		return 2
	
	# Check for regular success
	if in_roll <= skill:
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
func calculate(derived_from: Array[String], calculation_type: int, specs: Dictionary, table_incr: int, table_mod: int = 0) -> int:
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
			# Add up all the values of the keys in `derived_from` found in `specs`
			# Then run logic to decide based on the table
			var total = 0
			for key in derived_from:
				if specs.has(key):
					total += int(specs[key])
				else:
					push_error("Key '%s' in derived_from not found in specs dictionary." % key)
			total = table_calc(total, table_incr, table_mod)
			return total

		_:
			# Handle unexpected calculation types
			push_error("Invalid calculation type: %d" % calculation_type)
			return -1


func table_calc(total: int, table_incr: int, table_mod: int) -> int:
	# 1) Divide total by 5 and round up
	var base_value = ceili(float(total) / float(table_incr))
	
	# 2) Add (or subtract if body_part_mod is negative) the table_mod
	var result = base_value + table_mod
	
	# 3) Ensure the result is at least 1
	if result <= 0:
		result = 1
	
	return result



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
