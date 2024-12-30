@tool
class_name MoveAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_group("Attributes")
## Maximum movement distance for the unit.
@export var max_move_distance: int = 3
@export var ap_cost: int = 1
@export var rotate_speed: float = 4.0  ## Speed for rotating the unit
@export var move_speed: float = 5.5
@export var stopping_distance: float = 0.1
@export var acceleration_timer: float = 0.5  ## Half-second to accelerate movement speed
@export var rotation_acceleration_timer: float = 0.5  ## Half-second for rotation acceleration


var movement_curve: Curve3D

var curve_travel_offset: float = 0.0
var curve_length: float = 0.0

# Target position is a Vector3.
var position_list: Array[Vector3]


# Movement related states
var is_moving: bool = false  ## Tracks if the unit is moving
var timer: float = 0.0  ## Timer for adding delay if needed
var start_timer: float = 0.1
var current_speed: float = 0.0  ## Current speed of the unit
var ai_exit: bool = false  ## Used to control AI exit delay logic
var start_trigger: bool = false



var current_position_index: int
var event: ActivationEvent = null
var target_position: GridPosition = null
var unit: Unit = null



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.character
	if not unit or not target_position:
		if can_end(event):
			push_error("either no target position or no unit: " + event.to_string())
			end_ability(event)
			return
	#getting the grid positions from the pathfinding
	position_list = []
	var grid_position_list: Array[GridPosition] = (Pathfinding.instance
	.find_path(unit.get_grid_position(), target_position))
	
	if grid_position_list.is_empty():
		push_error("No valid path found to target position: " + target_position.to_str())
		if can_end(event):
			end_ability(event)
			return

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
	acceleration_timer = 0.2
	rotation_acceleration_timer = 0.3
	current_speed = 0.1
	start_timer = 0.1
	

	is_moving = true

	unit.animator.animate_movement_along_curve(move_speed, movement_curve, curve_length, 
	acceleration_timer, rotation_acceleration_timer, stopping_distance, rotate_speed)
	await unit.animator.movement_completed
	is_moving = false
	if can_end(event):
		end_ability(event)







func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list = get_valid_ability_target_grid_position_list(_event)
	for x: GridPosition in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false


## Gets a list of valid grid positions for movement.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	if _event.character.get_grid_position() == null:
		return []
	var self_unit = _event.character.get_grid_position()
	var valid_grid_position_list: Array[GridPosition] = []  # Initialize an empty array for valid grid positions.

	# Loop through the x and z ranges based on max_move_distance.
	for x in range(-max_move_distance, max_move_distance + 1):
		for z in range(-max_move_distance, max_move_distance + 1):
			# Create an offset grid position.
			var offset_grid_position = GridPosition.new(x, z)
			# Calculate the test grid position.
			var temp_grid_position: GridPosition = self_unit.add(offset_grid_position)
			var test_grid_object: GridObject = LevelGrid.grid_system.get_grid_object(temp_grid_position)
			if test_grid_object == null:
				continue
			var test_grid_position: GridPosition = test_grid_object.get_grid_position()

			# Skip invalid or occupied grid positions.
			if not LevelGrid.is_valid_grid_position(test_grid_position) or self_unit.equals(test_grid_position) or LevelGrid.has_any_unit_on_grid_position(test_grid_position):
				continue
			
			if not Pathfinding.instance.is_walkable(test_grid_position):
				continue
			
			if not Pathfinding.instance.is_path_available(self_unit, test_grid_position):
				continue
			if Pathfinding.instance.get_path_cost(self_unit, test_grid_position) > max_move_distance:
				# Path length is too long
				continue
			# Add the valid grid position to the list.
			valid_grid_position_list.append(test_grid_position)

	return valid_grid_position_list


# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
