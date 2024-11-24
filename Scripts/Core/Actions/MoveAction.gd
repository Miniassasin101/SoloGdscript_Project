# MoveAction.gd
# Handles the movement action of a unit.

class_name MoveAction
extends Action

# Signals to indicate start and stop of movement
signal on_start_moving
signal on_stop_moving


var movement_curve: Curve3D

var curve_travel_offset: float = 0.0
var curve_length: float = 0.0

# Target position is a Vector3.
var position_list: Array[Vector3]

# Maximum movement distance for the unit.
@export var max_move_distance: int = 3

# Movement speed of the unit.
const MOVE_SPEED: float = 5.5

# Distance threshold to stop moving when close to the target.
const STOPPING_DISTANCE: float = 0.1

var current_position_index: int

# Movement related states
var is_moving: bool = false  # Tracks if the unit is moving
var timer: float = 0.0  # Timer for adding delay if needed
var start_timer: float = 0.1
var acceleration_timer: float = 0.5  # Half-second to accelerate movement speed
var rotation_acceleration_timer: float = 0.5  # Half-second for rotation acceleration
var current_speed: float = 0.0  # Current speed of the unit
var rotate_speed: float = 2.0  # Speed for rotating the unit
var ai_exit: bool = false  # Used to control AI exit delay logic
var start_trigger: bool = false



# Called every frame. Handles movement and state changes.
func _process(delta: float) -> void:
	# Skip if action is not active
	if not is_active or not is_moving:
		return
	var target_position: Vector3 = position_list[current_position_index]
	if !start_trigger:
		start_timer -= delta
		if start_timer <= 0.0:
			start_trigger = true
		return
	# Move towards the target position if the unit is far enough.
	move_along_curve(delta)


func move_along_curve(delta: float) -> void:
	# If the unit reaches the end of the curve, stop moving.
	#fix is_enemy logic later
	if curve_travel_offset >= curve_length:
		if is_moving:
			on_stop_moving.emit()
			is_moving = false

			# Add a delay if the unit is an enemy to handle AI exit logic.
			if unit.is_enemy:
				await get_tree().create_timer(0.1).timeout
				super.action_complete()
				
			else:
				# Immediately complete the action if not an enemy.
				super.action_complete()
		return

	# Ensure `current_speed` is not zero to avoid getting stuck.
	if current_speed <= 0.0:
		current_speed = MOVE_SPEED  # Fallback to default speed

	# Get the current position on the curve.
	var current_position = unit.global_transform.origin
	var next_position: Vector3 = movement_curve.sample_baked(curve_travel_offset)
	var move_direction: Vector3 = (next_position - current_position).normalized()

	# Start movement if it hasn't already started.
	if not is_moving:
		on_start_moving.emit()
		is_moving = true

	# Accelerate movement speed smoothly over the first 0.5 seconds.
	if acceleration_timer > 0.0:
		acceleration_timer -= delta
		var acceleration_progress: float = 1.0 - (acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
		current_speed = lerp(0.0, MOVE_SPEED, acceleration_progress)
	else:
		current_speed = MOVE_SPEED  # After 0.5 seconds, use max speed

	# Move towards the next position with the current speed.
	var distance_to_next_point = current_position.distance_to(next_position)
	if distance_to_next_point > STOPPING_DISTANCE:
		current_position += move_direction * current_speed * delta
		unit.global_transform.origin = current_position

		# Smoothly accelerate the rotation towards the movement direction.
		if rotation_acceleration_timer > 0.0:
			rotation_acceleration_timer -= delta
			var rotation_progress: float = 1.0 - (rotation_acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
			rotate_speed = lerp(3.0, 7.0, rotation_progress)
		else:
			rotate_speed = 7.0  # Default rotation speed

		# Smoothly rotate the unit towards the movement direction.
		var target_rotation = Basis.looking_at(move_direction, Vector3.UP, true)
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
		unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	# Increment the travel offset along the curve.
	curve_travel_offset += min(current_speed * delta, curve_length - curve_travel_offset)

	# Handle enemy unit AI exit logic if no movement is required.
	if unit.is_enemy and timer > 0.0:
		timer -= delta
		if timer <= 0.0 and ai_exit:
			super.action_complete()
			ai_exit = false








func take_action(grid_position: GridPosition) -> void:
	var grid_position_list: Array[GridPosition] = Pathfinding.instance.find_path(unit.get_grid_position(), grid_position)
	if grid_position_list.is_empty():
		push_error("No valid path found to target position: ", grid_position)
		super.action_complete()
		return

	position_list = []
	movement_curve = Curve3D.new()
	movement_curve.bake_interval = 0.2  # Adjust for smoothness

	for position: GridPosition in grid_position_list:
		position_list.append(LevelGrid.get_world_position(position))

	# Add points to the curve
	for i in range(position_list.size()):
		var point = position_list[i]
		var control_offset = Vector3(0, 0, 0)
		if i > 0 and i < position_list.size() - 1:
			# Smooth control points for intermediate nodes
			control_offset = (position_list[i + 1] - position_list[i - 1]).normalized() * 0.5
		movement_curve.add_point(point, -control_offset, control_offset)

	# Store curve length and reset offset
	curve_length = movement_curve.get_baked_length()
	curve_travel_offset = 0.0
	is_moving = true
	on_start_moving.emit()
	acceleration_timer = 0.2
	rotation_acceleration_timer = 0.3
	current_speed = 0.1
	start_timer = 0.1

	action_start()



# Checks if the grid position is valid for movement.
func is_valid_action_grid_position(grid_position: GridPosition) -> bool:
	return super.is_valid_action_grid_position(grid_position)

# Gets a list of valid action grid positions.
func get_valid_action_grid_position_list() -> Array:
	var unit_grid_position: GridPosition = unit.get_grid_position()
	var valid_pos_list: Array = get_valid_action_grid_position_list_input(unit_grid_position)
	return valid_pos_list

# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list_input(unit_grid_position: GridPosition) -> Array:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.

	# Loop through the x and z ranges based on max_move_distance.
	for x in range(-max_move_distance, max_move_distance + 1):
		for z in range(-max_move_distance, max_move_distance + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			var temp_grid_position: GridPosition = unit_grid_position.add(offset_grid_position)
			var test_grid_object: GridObject = LevelGrid.grid_system.get_grid_object(temp_grid_position)
			if test_grid_object == null:
				continue
			var test_grid_position: GridPosition = test_grid_object.get_grid_position()

			# Skip invalid or occupied grid positions.
			if not LevelGrid.is_valid_grid_position(test_grid_position) or unit_grid_position.equals(test_grid_position) or LevelGrid.has_any_unit_on_grid_position(test_grid_position):
				continue
			
			if not Pathfinding.instance.is_walkable(test_grid_position):
				continue
			
			if not Pathfinding.instance.is_path_available(unit_grid_position, test_grid_position):
				continue
			if Pathfinding.instance.get_path_cost(unit_grid_position, test_grid_position) > max_move_distance:
				# Path length is too long
				continue
			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)

	return valid_grid_position_list

# Converts a list of GridPosition to a list of their string representations.
func position_list_to_strings(pos_list: Array) -> Array:
	return super.position_list_to_strings(pos_list)

# Returns the name of the action.
func get_action_name() -> String:
	return "Move"

# Gets the best AI action for a specified grid position.
func get_enemy_ai_action(grid_position: GridPosition):
	var target_count_at_grid_position: int = unit.get_action("Shoot").get_target_count_at_position(grid_position)
	var enemy_ai_action: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_action.action_value = target_count_at_grid_position * 10
	enemy_ai_action.grid_position = grid_position
	return enemy_ai_action

# Gets the number of targets at a specified grid position.
func get_target_count_at_position(grid_position: GridPosition) -> int:
	return get_valid_action_grid_position_list_input(grid_position).size()
