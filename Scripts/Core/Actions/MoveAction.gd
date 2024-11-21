# MoveAction.gd
# Handles the movement action of a unit.

class_name MoveAction
extends Action

# Signals to indicate start and stop of movement
signal on_start_moving
signal on_stop_moving

# Target position is a Vector3.
var target_position: Vector3

# Maximum movement distance for the unit.
@export var max_move_distance: int = 3

# Movement speed of the unit.
const MOVE_SPEED: float = 5.5

# Distance threshold to stop moving when close to the target.
const STOPPING_DISTANCE: float = 0.1

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

func _ready() -> void:
	super._ready()
	# Initialize target position to the unit's current position.
	target_position = unit.global_transform.origin

# Called every frame. Handles movement and state changes.
func _process(delta: float) -> void:
	# Skip if action is not active
	if not is_active:
		return

	# Handle delay for enemy unit
	if unit.is_enemy and timer > 0.0:
		timer -= delta
	if timer <= 0.0 and ai_exit:
		super.action_complete()
		ai_exit = false
		start_trigger = false
		return
	if !start_trigger:
		start_timer -= delta
		if start_timer <= 0.0:
			start_trigger = true
		return
	# Move towards the target position if the unit is far enough.
	move_towards_target(delta)

# Moves the unit towards the target position.
func move_towards_target(delta: float) -> void:
	# Get the unit's current position.
	var current_position = unit.global_transform.origin
	# Calculate the movement direction.
	var move_direction: Vector3 = (target_position - current_position).normalized()

	# Check if the unit needs to move.
	if current_position.distance_to(target_position) > STOPPING_DISTANCE:
		# Set the walking animation condition to true when starting movement.
		if not is_moving:
			on_start_moving.emit()
			is_moving = true

		# Accelerate movement speed smoothly over the first 0.5 seconds
		if acceleration_timer > 0.0:
			acceleration_timer -= delta
			var acceleration_progress: float = 1.0 - (acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
			current_speed = lerp(0.0, MOVE_SPEED, acceleration_progress)
		else:
			current_speed = MOVE_SPEED  # After 0.5 seconds, use max speed

		# Move towards the target position with the current speed.
		current_position += move_direction * current_speed * delta
		unit.global_transform.origin = current_position  # Update the unit's position.

		# Smoothly accelerate the rotation towards the movement direction
		if rotation_acceleration_timer > 0.0:
			rotation_acceleration_timer -= delta
			var rotation_progress: float = 1.0 - (rotation_acceleration_timer / 0.5)  # Interpolation factor from 0 to 1
			rotate_speed = lerp(1.0, 3.0, rotation_progress)
		else:
			rotate_speed = 3.0  # Default rotation speed

		# Smoothly rotate the unit towards the movement direction
		var target_rotation = Basis.looking_at(move_direction, Vector3.UP, true)
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)
		unit.global_transform.basis = unit.global_transform.basis.orthonormalized()

	else:
		# If the unit has reached the target, stop the walking animation.
		if is_moving:
			on_stop_moving.emit()
			is_moving = false

			# Add a delay if the unit is an enemy to add AI action completion timing
			if unit.is_enemy:
				timer = 0.1
				ai_exit = true
			else:
				# Immediately complete the action if not an enemy
				start_trigger = false
				super.action_complete()

	# Smoothly rotate the unit towards the movement direction if still moving.
	if is_active:
		var target_rotation = Basis.looking_at(-move_direction, Vector3.UP)
		rotate_speed = 3.0
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)

# Begins the movement action to a specified grid position.
func take_action(grid_position: GridPosition) -> void:
	if not is_valid_action_grid_position(grid_position):
		print("Invalid move to grid position: ", grid_position.to_str())
		return

	action_start()

	# Reset timers for smooth acceleration and rotation
	acceleration_timer = 0.3
	rotation_acceleration_timer = 0.3
	current_speed = 0.0
	start_timer = 0.1

	# Convert the grid position to world position and set as target.
	self.target_position = LevelGrid.get_world_position(grid_position)

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
