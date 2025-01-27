@tool
class_name MoveAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_group("Attributes")
## Maximum movement distance for the unit.
@export var max_move_distance: int = 3
@export var use_max_move_distance: bool = false
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
	var path_package: PathPackage = Pathfinding.instance.get_path_package(target_position, unit, true, true)
	var grid_position_list: Array[GridPosition] = path_package.get_path()
	
	if grid_position_list.is_empty():
		push_error("No valid path found to target position: " + target_position.to_str())
		if can_end(event):
			end_ability(event)
			return

	movement_curve = Curve3D.new()
	movement_curve.bake_interval = 0.2  # Adjust for smoothness
	

	position_list.append_array(LevelGrid.get_world_positions(path_package.get_path()))
	
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
	await unit.animator.movement_completed # add another signal for interruption
	unit.add_distance_moved(path_package.get_cost())
	if unit.current_gait >= Utilities.MovementGait.RUN:
		unit.animator.rotate_unit_towards_facing(unit.facing)

	
	is_moving = false
	if can_end(event):
		event.successful = true
		end_ability(event)







func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list = get_valid_ability_target_grid_position_list(_event)
	for x: GridPosition in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false








func get_valid_ability_target_grid_position_list_dep(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.character
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []
	
	var valid_positions: Array[GridPosition] = []
	var max_range: float = float(max_move_distance) if use_max_move_distance else in_unit.get_max_move_left()
	var gait: int = in_unit.current_gait

	if gait in [Utilities.MovementGait.RUN, Utilities.MovementGait.SPRINT]:
		# 1) Get the normal forward cone of possible squares.
		var front_cone: Array[GridPosition] = []
		var facing: int = in_unit.facing
		for distance in range(1, max_range + 1):
			for offset in range(-distance, distance + 1):
				var temp_pos: GridPosition = null
				match facing:
					Utilities.FACING.NORTH:
						temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
							self_unit_pos.x + offset,
							self_unit_pos.z - distance
						)
					Utilities.FACING.EAST:
						temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
							self_unit_pos.x + distance,
							self_unit_pos.z + offset
						)
					Utilities.FACING.SOUTH:
						temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
							self_unit_pos.x + offset,
							self_unit_pos.z + distance
						)
					Utilities.FACING.WEST:
						temp_pos = LevelGrid.grid_system.get_grid_position_from_coords(
							self_unit_pos.x - distance,
							self_unit_pos.z + offset
						)
				
				if temp_pos != null and LevelGrid.is_valid_grid_position(temp_pos):
					front_cone.append(temp_pos)

		# Filter out blocked or out-of-range squares from front cone.
		var final_front_cone: Array[GridPosition] = []
		for fc in front_cone:
			if Pathfinding.instance.is_walkable(fc):
				# We'll do a path cost check later; for now just keep it
				final_front_cone.append(fc)

		# 2) Make a large shell from behind, remove intersection with the front.
		var shell_positions: Array[GridPosition] = Utilities.get_shell_cone_from_behind(in_unit, max_range)

		for fpos in final_front_cone:
			shell_positions.erase(fpos)  # remove any that appear in front cone

		# 3) Temporarily disable the shell squares that are currently enabled.
		var actually_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(shell_positions)

		# 4) Now check which squares in front_cone are truly reachable 
		#    (meaning there's a path that doesn't rely on going behind).
		for candidate: GridPosition in final_front_cone:
			# If we can path from our current tile to candidate with cost <= max_range, keep it.
			# (You can also use is_path_available or your path cost logic.)
			var path_cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, candidate)
			var path_available: bool = Pathfinding.instance.is_path_available(self_unit_pos, candidate)
			if path_available:
				var path: Array[GridPosition] = Pathfinding.instance.find_path(self_unit_pos, candidate)
				if !Utilities.is_cone_path_available(in_unit, path):
					continue
			
			if (path_cost <= max_range and path_cost < INF) and (path_available) and not LevelGrid.has_any_unit_on_grid_position(candidate):
				valid_positions.append(candidate)



		Pathfinding.instance.reenable_positions(actually_disabled)

	else:
		# Normal behavior for other gaits
		for x in range(-max_range, max_range + 1):
			for z in range(-max_range, max_range + 1):
				var temp_grid_position: GridPosition = LevelGrid.grid_system.get_grid_position_from_grid_position(self_unit_pos.add(
					GridPosition.new(x, z))  # Or see if you have a get_grid_position_from_coords
				)
				if not LevelGrid.is_valid_grid_position(temp_grid_position):
					continue
				
				if not Pathfinding.instance.is_path_available(self_unit_pos, temp_grid_position):
					continue
				
				if not self_unit_pos.equals(temp_grid_position) \
						and not LevelGrid.has_any_unit_on_grid_position(temp_grid_position):
					valid_positions.append(temp_grid_position)

	return valid_positions



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.character
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []

	var valid_positions: Array[GridPosition] = []
	var max_range: float = float(max_move_distance) if use_max_move_distance else in_unit.get_max_move_left()
	var gait: int = in_unit.current_gait

	if gait in [Utilities.MovementGait.RUN, Utilities.MovementGait.SPRINT]:
		# 1) Generate all potential grid positions in the front cone
		var front_cone: Array[GridPosition] = Utilities.get_front_cone(in_unit, int(max_range))

		# 2) Filter positions based on walkability and path cost
		var valid_front_positions: Array[GridPosition] = []
		for pos in front_cone:
			if LevelGrid.is_valid_grid_position(pos) and Pathfinding.instance.is_walkable(pos):
				# Calculate cost once and reuse
				var path_cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, pos)
				if path_cost <= max_range and path_cost < INF:
					valid_front_positions.append(pos)

		# 3) Temporarily disable shell positions that overlap
		var shell_positions: Array[GridPosition] = Utilities.get_shell_cone_from_behind(in_unit, max_range)
		for pos in valid_front_positions:
			shell_positions.erase(pos)  # Remove positions already in the front cone
		var actually_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(shell_positions)

		# 4) Verify paths for cone availability only once
		for candidate in valid_front_positions:
			var path: Array[GridPosition] = Pathfinding.instance.find_path(self_unit_pos, candidate)
			if Utilities.is_cone_path_available(in_unit, path):
				valid_positions.append(candidate)

		# Re-enable temporarily disabled positions
		Pathfinding.instance.reenable_positions(actually_disabled)

	else:
		# Standard behavior for non-cone-based movement
		for x in range(-max_range, max_range + 1):
			for z in range(-max_range, max_range + 1):
				var temp_grid_position: GridPosition = LevelGrid.grid_system.get_grid_position_from_coords(
					self_unit_pos.x + x, 
					self_unit_pos.z + z
				)
				if temp_grid_position != null and LevelGrid.is_valid_grid_position(temp_grid_position):
					if not LevelGrid.has_any_unit_on_grid_position(temp_grid_position) \
							and Pathfinding.instance.is_walkable(temp_grid_position):
						# Calculate path cost once and reuse
						var path_cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, temp_grid_position)
						if path_cost <= max_range and path_cost < INF:
							valid_positions.append(temp_grid_position)

	return valid_positions




func get_max_move_from_gait(_event: ActivationEvent) -> float:
	var in_unit: Unit = _event.character
	var move_rate: float = in_unit.attribute_map.get_attribute_by_name("movement_rate").current_buffed_value
	var gait: int = in_unit.current_gait
	var ret_move: float = 0.0
	match gait:
		Utilities.MovementGait.HOLD_GROUND:
			push_error("Move Ability Called when gait is HOLD_GROUND on unit: ", unit.name)
			return 0.0

		Utilities.MovementGait.WALK:
			ret_move += (move_rate/2.0)
		
		Utilities.MovementGait.RUN:
			ret_move += ((move_rate * 3.0) / 2.0)

		Utilities.MovementGait.SPRINT:
			ret_move += ((move_rate * 5.0) / 2.0)
		_:
			push_error("Invalid Gait on unit: ", in_unit.name)
			ret_move += 0.0
	
	return maxf((ret_move - in_unit.distance_moved_this_turn), 0.0)

# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
