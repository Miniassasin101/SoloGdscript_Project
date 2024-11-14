# MoveAction.gd
# Handles the movement action of a unit.

class_name MoveAction
extends Action

# Target position is a Vector3.
var target_position: Vector3

# Maximum movement distance for the unit.
@export var max_move_distance: int = 3

# References initialized when the node enters the scene tree.
@onready var mouse_world: MouseWorld = $"../MouseWorld"
@onready var level_grid: LevelGrid = LevelGrid
var animation_tree: AnimationTree

# Movement speed of the unit.
const MOVE_SPEED: float = 4.0

# Distance threshold to stop moving when close to the target.
const STOPPING_DISTANCE: float = 0.1

func _ready() -> void:
	super._ready()
	animation_tree = unit.get_animation_tree()
	# Initialize target position to the unit's current position.
	target_position = unit.global_transform.origin

func _process(delta: float) -> void:
	if not is_active:
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
		# Move towards the target position.
		current_position += move_direction * MOVE_SPEED * delta
		unit.global_transform.origin = current_position  # Update the unit's position.

		# Smoothly rotate the unit towards the movement direction.
		var target_rotation = Basis.looking_at(-move_direction, Vector3.UP)
		var rotate_speed: float = 8.0
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)

		# Set the walking animation condition to true.
		if animation_tree:
			animation_tree.set("parameters/conditions/IsWalking", true)
	else:
		# If the unit has reached the target, stop the walking animation.
		if animation_tree:
			animation_tree.set("parameters/conditions/IsWalking", false)
		is_active = false
		print_debug("move is_active = false")
		SignalBus.action_complete.emit()

	# Smoothly rotate the unit towards the movement direction if still moving.
	if is_active:
		var target_rotation = Basis.looking_at(-move_direction, Vector3.UP)
		var rotate_speed: float = 8.0
		unit.global_transform.basis = unit.global_transform.basis.slerp(target_rotation, delta * rotate_speed)

# Updates the target position based on the mouse click.
func update_target_position() -> void:
	# Get the mouse position from MouseWorld.
	var result: Dictionary = mouse_world.get_mouse_position()
	
	# If raycast hit an object, update the unit's target position.
	if result != null:
		var grid_position: GridPosition = level_grid.get_grid_position(result["position"])
		take_action(grid_position)

func take_action(grid_position: GridPosition) -> void:
	if not is_valid_action_grid_position(grid_position):
		print("Invalid move to grid position: ", grid_position.to_str())
		return
	# Convert the grid position to world position and set as target.
	is_active = true
	self.target_position = level_grid.get_world_position(grid_position)

# Checks if the grid position is valid for movement.
func is_valid_action_grid_position(grid_position: GridPosition) -> bool:
	return super.is_valid_action_grid_position(grid_position)

# Gets a list of valid grid positions for movement.
func get_valid_action_grid_position_list() -> Array:
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.
	var unit_grid_position: GridPosition = unit.get_grid_position()
	# Loop through the x and z ranges based on max_move_distance.
	for x in range(-max_move_distance, max_move_distance + 1):
		for z in range(-max_move_distance, max_move_distance + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			var test_grid_position: GridPosition = unit_grid_position.add(offset_grid_position)
			
			# Skip invalid grid positions.
			if not level_grid.is_valid_grid_position(test_grid_position):
				continue
			# Skip the current unit's grid position.
			if unit_grid_position.equals(test_grid_position):
				continue
			# Skip grid positions that are occupied.
			if level_grid.has_any_unit_on_grid_position(test_grid_position):
				continue
				
			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)
	return valid_grid_position_list

# Converts a list of GridPosition to a list of their string representations.
func position_list_to_strings(pos_list: Array) -> Array:
	return super.position_list_to_strings(pos_list)

func get_action_name() -> String:
	return "Move"

func print_sleep_in_spanish():
	print("Dormir")
