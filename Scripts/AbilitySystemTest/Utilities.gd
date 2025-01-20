## Global Autoload Singleton
## Manages any utilities and calculations for the ability system
extends Node

# Enum and Const

enum MovementGait {
	HOLD_GROUND,
	WALK,
	RUN,
	SPRINT
}

## Speed multipliers for each gait (times the unit’s base movement rate).
const GAIT_SPEED_MULTIPLIER = {
	MovementGait.HOLD_GROUND: 0,
	MovementGait.WALK: 1.0,
	MovementGait.RUN: 3.0,
	MovementGait.SPRINT: 5.0
}

## Is the game's internal facing system.
## North = -z, East = +x, South = +z, West = -x.
enum FACING {
	NORTH,
	EAST,
	SOUTH,
	WEST
}


## Allowed actions for each gait 
## (strings here are just examples; adapt them to your actual action names)
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



func get_adjacent_tiles_no_diagonal(unit: Unit) -> Array[GridPosition]:
	var ret_tiles: Array[GridPosition] = []
	ret_tiles.append(get_back_tile(unit))
	ret_tiles.append_array(get_side_tiles(unit))
	ret_tiles.append(get_front_tile(unit))

	return ret_tiles.filter(func(gridpos): return gridpos != null) # Remove null values
	

func get_adjacent_tiles_with_diagonal(unit: Unit) -> Array[GridPosition]:
	var ret_tiles: Array[GridPosition] = []
	ret_tiles.append(get_back_tiles(unit))
	ret_tiles.append(get_side_tiles(unit))
	ret_tiles.append(get_front_tiles(unit))

	return ret_tiles.filter(func(gridpos): return gridpos != null) # Remove null values



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



func get_front_tile(unit: Unit) -> GridPosition:
	var facing: int = unit.facing
	var grid_position: GridPosition = unit.grid_position

	# Get the grid positions of the three front tiles based on the facing direction
	match facing:
		0:  # Facing North
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))      # Center front
		1:  # Facing East
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))      # Center front
		2:  # Facing South
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))      # Center front
		3:  # Facing West
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))      # Center front
	push_error("Facing not set on ", unit)
	return null




func get_side_tiles(unit: Unit) -> Array[GridPosition]:
	var facing: int = unit.facing
	var side_tiles: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

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


func get_back_tile(unit: Unit) -> GridPosition:
	var facing: int = unit.facing
	var grid_position: GridPosition = unit.grid_position

	# Get the grid positions of the three back tiles based on the facing direction
	match facing:
		0:  # Facing North
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))      # Center back
		1:  # Facing East
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))      # Center back
		2:  # Facing South
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))      # Center back
		3:  # Facing West
			return (LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))      # Center back
	push_error("Facing not set on ", unit)
	return null


# Functions to get tiles within immidiate range.

func get_right_side_tile(unit: Unit) -> GridPosition:
	var facing: int = unit.facing
	var grid_position: GridPosition = unit.grid_position

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
	push_error("Facing not set on ", unit)
	return null


func get_left_side_tile(unit: Unit) -> GridPosition:
	var facing: int = unit.facing
	var grid_position: GridPosition = unit.grid_position

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
	push_error("Facing not set on ", unit)
	return null




# Functions to get cones:

# Function to get front cone tiles
func get_front_cone(unit: Unit, max_range: int) -> Array[GridPosition]:
	var facing: int = unit.facing
	var front_cone: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var temp_pos: GridPosition = null
			match facing:
				0:  # North
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)
				1:  # East
					temp_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
				2:  # South
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)
				3:  # West
					temp_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
			if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
				front_cone.append(temp_pos)

	return LevelGrid.get_grid_positions_from_grid_positions(front_cone)

# Function to get back cone tiles
func get_back_cone(unit: Unit, max_range: int) -> Array[GridPosition]:
	var facing: int = unit.facing
	var back_cone: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var temp_pos: GridPosition = null
			match facing:
				0:  # North
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)
				1:  # East
					temp_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
				2:  # South
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)
				3:  # West
					temp_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
			if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
				back_cone.append(temp_pos)

	return LevelGrid.get_grid_positions_from_grid_positions(back_cone)

# Function to get side cone tiles
func get_side_cone(unit: Unit, max_range: int) -> Array[GridPosition]:
	var facing: int = unit.facing
	var side_cone: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var left_pos: GridPosition = null
			var right_pos: GridPosition = null
			match facing:
				0:  # North
					left_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
					right_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
				1:  # East
					left_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)
					right_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)
				2:  # South
					left_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
					right_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
				3:  # West
					left_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)
					right_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)

			if left_pos != null and LevelGrid.is_valid_grid_position(left_pos):
				side_cone.append(left_pos)
			if right_pos != null and LevelGrid.is_valid_grid_position(right_pos):
				side_cone.append(right_pos)

	return LevelGrid.get_grid_positions_from_grid_positions(side_cone)


# Function to get left cone tiles
func get_left_cone(unit: Unit, max_range: int) -> Array[GridPosition]:
	var facing: int = unit.facing
	var left_cone: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var temp_pos: GridPosition = null
			match facing:
				0:  # North
					temp_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
				1:  # East
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)
				2:  # South
					temp_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
				3:  # West
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)

			if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
				left_cone.append(temp_pos)
				

	return LevelGrid.get_grid_positions_from_grid_positions(left_cone)

# Function to get right cone tiles
func get_right_cone(unit: Unit, max_range: int) -> Array[GridPosition]:
	var facing: int = unit.facing
	var right_cone: Array[GridPosition] = []
	var grid_position: GridPosition = unit.grid_position

	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var temp_pos: GridPosition = null
			match facing:
				0:  # North
					temp_pos = GridPosition.new(grid_position.x + distance, grid_position.z + offset)
				1:  # East
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z + distance)
				2:  # South
					temp_pos = GridPosition.new(grid_position.x - distance, grid_position.z + offset)
				3:  # West
					temp_pos = GridPosition.new(grid_position.x + offset, grid_position.z - distance)

			if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
				right_cone.append(temp_pos)

	return right_cone





# Calculation Functions for Skills and other die rolls

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

## Stand in for any logic for getting values from tables
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
