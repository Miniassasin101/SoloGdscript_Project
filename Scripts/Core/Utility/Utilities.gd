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


enum DIFFICULTY_GRADE {
	VERY_EASY,
	EASY,
	STANDARD,
	HARD,
	FORMIDABLE,
	HERCULEAN,
	HOPELESS
}

const DIFFICULTY_GRADE_MULTIPLIER = {
	DIFFICULTY_GRADE.VERY_EASY: 2.0,
	DIFFICULTY_GRADE.EASY: 1.5,
	DIFFICULTY_GRADE.STANDARD: 1.0,
	DIFFICULTY_GRADE.HARD: 0.77,
	DIFFICULTY_GRADE.FORMIDABLE: 0.5,
	DIFFICULTY_GRADE.HERCULEAN: 0.1,
	DIFFICULTY_GRADE.HOPELESS: 0.0,
}


# An enum to describe the relative positions.
enum RelativePosition { FRONT, RIGHT_SIDE, LEFT_SIDE, BACK, UNKNOWN }


const DIR_TO_OFF = {
	GridObject.CoverDir.NORTH: Vector2(0, -1),
	GridObject.CoverDir.EAST:  Vector2(1,  0),
	GridObject.CoverDir.SOUTH: Vector2(0,  1),
	GridObject.CoverDir.WEST:  Vector2(-1, 0),
}




# This helper returns the relative position of focus from relative.
# Whoever is calling this is the focus.
# FIXME: Wont work on map edges
func get_unit_relative_position(focus_unit: Unit, relative_unit: Unit) -> RelativePosition:
	var relative_pos: GridPosition = relative_unit.get_grid_position()
	
	var front_focus: Array[GridPosition] = get_front_tiles(focus_unit)
	var back_focus: Array[GridPosition] = get_back_tiles(focus_unit)
	var right_focus: GridPosition = get_right_side_tile(focus_unit)
	var left_focus: GridPosition = get_left_side_tile(focus_unit)
	if front_focus.has(relative_pos):
		return RelativePosition.FRONT
	elif back_focus.has(relative_pos):
		return RelativePosition.BACK
	elif right_focus and right_focus.equals(relative_pos):
		return RelativePosition.RIGHT_SIDE
	elif left_focus and left_focus.equals(relative_pos):
		return RelativePosition.LEFT_SIDE
	return RelativePosition.UNKNOWN

func get_cone_relative_position(focus_unit: Unit, relative_unit: Unit) -> RelativePosition:
	var focus_position: GridPosition = focus_unit.get_grid_position()
	var relative_position: GridPosition = relative_unit.get_grid_position()
	
	# Calculate distance between the two units using a simple manhattan distance
	var distance: int = abs(focus_position.x - relative_position.x) + abs(focus_position.z - relative_position.z)
	
	# Precalculate cone areas based on the distance
	var front_cone: Array[GridPosition] = get_front_cone(focus_unit, distance)
	# Check which cone contains the relative unit's position
	if front_cone.has(relative_position):
		return RelativePosition.FRONT
	
	var back_cone: Array[GridPosition] = get_back_cone(focus_unit, distance)
	if back_cone.has(relative_position):
		return RelativePosition.BACK
	
	var left_cone: Array[GridPosition] = get_left_cone(focus_unit, distance)
	if left_cone.has(relative_position):
		return RelativePosition.LEFT_SIDE
	
	var right_cone: Array[GridPosition] = get_right_cone(focus_unit, distance)
	
	if right_cone.has(relative_position):
		return RelativePosition.RIGHT_SIDE
	
	return RelativePosition.UNKNOWN


func get_adjacent_tiles_no_diagonal(unit: Unit) -> Array[GridPosition]:
	if unit == null: return []
	var ret_tiles: Array[GridPosition] = []
	ret_tiles.append(get_back_tile(unit))
	ret_tiles.append_array(get_side_tiles(unit))
	ret_tiles.append(get_front_tile(unit))

	return ret_tiles.filter(func(gridpos): return gridpos != null) # Remove null values
	

func get_adjacent_tiles_with_diagonal(unit: Unit) -> Array[GridPosition]:
	if unit == null: return []
	var ret_tiles: Array[GridPosition] = []
	ret_tiles.append_array(get_back_tiles(unit))
	ret_tiles.append_array(get_side_tiles(unit))
	ret_tiles.append_array(get_front_tiles(unit))

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
	return GridPosition.new(-1, -1)




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
	return GridPosition.new(-1, -1)


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
	return GridPosition.new(-1, -1)


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
	return GridPosition.new(-1, -1)




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

	return LevelGrid.get_grid_positions_from_grid_positions(right_cone)


func get_shell_cone_from_behind(unit: Unit, max_range: float) -> Array[GridPosition]:
	var shell_positions: Array[GridPosition] = []
	var behind_pos: GridPosition = get_back_tile(unit)
	if behind_pos == null:
		return shell_positions  # nothing if no behind tile

	var facing: int = unit.facing
	for distance in range(1, max_range + 1):
		for offset in range(-distance, distance + 1):
			var temp_pos: GridPosition = null
			match facing:
				FACING.NORTH:
					temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
						behind_pos.x + offset, 
						behind_pos.z - distance
					)
				FACING.EAST:
					temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
						behind_pos.x + distance,
						behind_pos.z + offset
					)
				FACING.SOUTH:
					temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
						behind_pos.x + offset, 
						behind_pos.z + distance
					)
				FACING.WEST:
					temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
						behind_pos.x - distance,
						behind_pos.z + offset
					)

			if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
				shell_positions.append(temp_pos)
	shell_positions.append_array(get_back_tiles(unit))
	return shell_positions



func get_front_tiles_from_position(grid_position: GridPosition, facing: int) -> Array[GridPosition]:
	var front_tiles: Array[GridPosition] = []

	match facing:
		Utilities.FACING.NORTH:
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z - 1))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Right front
		Utilities.FACING.EAST:
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z - 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Right front
		Utilities.FACING.SOUTH:
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x + 1, grid_position.z + 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x, grid_position.z + 1))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Right front
		Utilities.FACING.WEST:
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z + 1))  # Left front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z))      # Center front
			front_tiles.append(LevelGrid.grid_system.get_grid_position_from_coords(grid_position.x - 1, grid_position.z - 1))  # Right front

	return front_tiles.filter(func(gridpos: GridPosition): return LevelGrid.is_valid_grid_position(gridpos))



func is_cone_path_available(unit: Unit, path: Array[GridPosition]) -> bool:
	if path.is_empty():
		return false  # No path to evaluate

	var facing_direction: int = unit.facing

	# Start validation from the second position in the path
	for i in range(1, path.size()):
		var current_position: GridPosition = path[i - 1]
		var next_position: GridPosition = path[i]

		# Get the valid front grid positions for the current position and facing direction
		var front_positions: Array[GridPosition] = get_front_tiles_from_position(current_position, facing_direction)

		# If the next step is not in the front positions, return false
		if not front_positions.has(next_position):
			return false

	return true  # All steps are valid



# Calculation Functions for Skills and other die rolls

func check_success_level(skill: int, in_roll: int) -> int:
	# Check for critical failure
	if in_roll == 98 or in_roll == 99 or in_roll == 100:
		return -1
	
	# Check for critical success
	if in_roll <= ceil(skill * 0.1):  # 10% of skill value rounded up
		return 2
	
	# Check for regular success
	if in_roll <= skill:
		return 1
	
	# Otherwise, it's a failure
	return 0

func get_crit_value_of_skill(skill: int) -> int:
	return ceili(skill * 0.1)


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



# Visual Utilities

# Material Utilities

func set_color_on_mesh(mesh: MeshInstance3D ,color: Color = Color.DEEP_SKY_BLUE, remove_overlay: bool = false) -> void:
	if remove_overlay:
		mesh.set_material_overlay(null)
		return
	var mesh_mat: StandardMaterial3D = preload("res://Hero_Game/Art/Materials/UnitMaterials/UnitVFXMaterials/GeneralHitFXMaterial.tres").duplicate(true)
	mesh_mat.set_albedo(color)
	mesh.set_material_overlay(mesh_mat)

func flash_color_on_meshes(meshes: Array[MeshInstance3D] ,color: Color = Color.DEEP_SKY_BLUE, flash_time: float = 1.0) -> void:
	for mesh in meshes:
		var mesh_mat: StandardMaterial3D = preload("res://Hero_Game/Art/Materials/UnitMaterials/UnitVFXMaterials/GeneralHitFXMaterial.tres").duplicate(true)
		mesh_mat.set_albedo(color)
		mesh.set_material_overlay(mesh_mat)
	
	await get_tree().create_timer(flash_time).timeout
	
	for mesh in meshes:
		mesh.set_material_overlay(null)


func flash_color_on_mesh(mesh: MeshInstance3D ,color: Color = Color.DEEP_SKY_BLUE, flash_time: float = 1.0) -> void:

	var mesh_mat: StandardMaterial3D = preload("res://Hero_Game/Art/Materials/UnitMaterials/UnitVFXMaterials/GeneralHitFXMaterial.tres").duplicate(true)
	mesh_mat.set_albedo(color)
	mesh.set_material_overlay(mesh_mat)
	
	await get_tree().create_timer(flash_time).timeout
	
	mesh.set_material_overlay(null)



# Text Utilities
func spawn_text_line(in_unit: Unit, text: String, color: Color = Color.SNOW, scale: float = 1.0, at_pos: Vector3 = Vector3.ZERO) -> void:
	if !in_unit:
		return
	var add_to_q: bool = false
	if at_pos == Vector3.ZERO:
		add_to_q = true
		at_pos = in_unit.get_world_position_above_marker()
	var camera: Camera3D = MouseWorld.instance.camera
	var screen_pos: Vector2 = camera.unproject_position(at_pos)

	# Instance the label
	var text_label_scene: PackedScene = UILayer.instance.text_controller_scene
	var text_label = text_label_scene.instantiate() as TextController
	
	# Add to CharacterLogQueue instead of UILayer directly
	if add_to_q:
		UILayer.instance.get_node("CharacterLogQueue").add_message(text_label)
	else:
		UILayer.instance.add_child(text_label)

	# Position it in screen-space
	text_label.set_position(screen_pos)
	text_label.world_pos = at_pos
	text_label.set_scale(Vector2(scale, scale))
	text_label.set_text_color(color)

	# Initialize the label's text, color, etc.
	text_label.play(text)



func spawn_damage_label(in_unit: Unit, damage_val: float, color: Color = Color.CRIMSON, scale: float = 0.6) -> void:
	var chest_pos: Vector3 = in_unit.get_world_position_chest()
	var camera: Camera3D = MouseWorld.instance.camera
	# Assume 'camera' is a reference to your Camera3D node
	var screen_pos: Vector2 = camera.unproject_position(chest_pos)
	
	# Now instance the label
	var text_label_scene: PackedScene = UILayer.instance.text_controller_scene
	var text_label = text_label_scene.instantiate() as TextController
	UILayer.instance.add_child(text_label)
	# Position it in screen-space
	text_label.set_position(screen_pos)
	text_label.set_scale(Vector2(scale, scale))
	text_label.world_pos = chest_pos
	text_label.set_text_color(color)
	
	# Initialize the label's text, color, etc.
	text_label.play(str(int(damage_val)), "DamageNumberAnim")



var slowdown_end_time: float = 0.0
var slowdown_active: bool = false

# Call this function to change the game speed (e.g., slow down or speed up)
# new_time_scale: the desired time scale (e.g., 0.5 for half speed, 2.0 for double speed)
# duration: how long (in seconds, using real time) to keep that speed before reverting to 1.0
func slow_game(new_time_scale: float = 1.0, duration: float = 0.7) -> void:
	# Immediately set the time scale.
	Engine.set_time_scale(new_time_scale)
	if new_time_scale != 1.0:
		await get_tree().create_timer(duration, true, false, true).timeout
		Engine.set_time_scale(1.0)
