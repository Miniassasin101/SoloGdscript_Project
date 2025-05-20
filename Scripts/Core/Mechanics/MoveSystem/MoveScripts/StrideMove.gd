class_name StrideMove
extends Move


@export_group("Attributes")
@export var max_move_distance: int = 3
@export var max_movement_left: float = 4.0
@export var movement_left: float = 4.0

@export var proc_count: int = 20


@export var use_max_move_distance: bool = false

@export var rotate_speed: float = 4.0  ## Speed for rotating the unit
@export var move_speed: float = 5.5
@export var stopping_distance: float = 0.1
@export var acceleration_timer: float = 0.2  ## Half-second to accelerate movement speed
@export var rotation_acceleration_timer: float = 0.3  ## Half-second for rotation acceleration

var movement_curve: Curve3D

var curve_travel_offset: float = 0.0
var curve_length: float = 0.0

# Target position is a Vector3.
var position_list: Array[Vector3] = []
 

var event: ActivationEvent = null
var target_position: GridPosition = null
var unit: Unit = null

var is_active: bool = false



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	target_position = event.target_grid_position
	unit = event.unit
	
	
	if not unit or not target_position:
		if can_end(event):
			push_error("either no target position or no unit: " + event.to_string())
			end_move(event)
			return

	# Getting the grid positions from the pathfinding
	position_list = []
	
	var temp_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(UnitManager.instance.get_enemy_positions(unit))
	
	var path_package: PathPackage = Pathfinding.instance.get_path_package(target_position, unit, true, true)
	var grid_position_list: Array[GridPosition] = path_package.get_path()
	
	
	if grid_position_list.is_empty():
		push_error("No valid path found to target position: " + target_position.to_str())
		if can_end(event):
			end_move(event)
			return
	
	var became_engaged: bool = false
	
	
	# Trim the path: stop the path as soon as a tile adjacent to an enemy is encountered.
	var trimmed_grid_path: Array[GridPosition] = []
	for grid_pos in grid_position_list:
		trimmed_grid_path.append(grid_pos)
		if grid_pos.equals(unit.get_grid_position()):
			continue
		if is_adjacent_to_new_enemy(grid_pos, unit):
			
			# Recalcs path cost based off of trimmed path
			path_package.path_cost = Pathfinding.instance.get_path_cost(unit.get_grid_position(), grid_pos)
			became_engaged = true
			break
	
	Pathfinding.instance.reenable_positions(temp_disabled)
	
	# Build the world position list from the trimmed grid path.
	position_list = LevelGrid.get_world_positions(trimmed_grid_path)
	
	movement_curve = Curve3D.new()
	movement_curve.bake_interval = 0.2  # Adjust for smoothness
	
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




	

	unit.animator.animate_movement_along_curve(move_speed, movement_curve, curve_length, 
		acceleration_timer, rotation_acceleration_timer, stopping_distance, rotate_speed)
	await unit.animator.movement_completed  # add another signal for interruption
	
	
	
	unit.add_distance_moved(path_package.get_cost())
	
	if !is_active:
		unit.increase_initiative_score(action_speed)

		unit.on_turn_started.connect(reset_movement.bind(unit))
		is_active = true
	
	movement_left -= path_package.get_cost()
	
	if became_engaged:
		movement_left = 0.0
	
	GridSystemVisual.instance.clear_highlights()
	
	#if unit.current_gait >= Utilities.MovementGait.RUN or became_engaged:
		#unit.animator.rotate_unit_towards_facing(unit.facing)
	unit.set_facing_then_rotate()
	
	if can_end(event):
		event.successful = true
		end_move(event)
	

func reset_movement(_unit: Unit) -> void:
	_unit.on_turn_started.disconnect(reset_movement)
	is_active = false
	movement_left = max_movement_left # FIXME: Replace with unit movement rate


# Helper function to check if a grid position is adjacent (including diagonally) to an enemy unit.
func is_adjacent_to_new_enemy(grid_pos: GridPosition, moving_unit: Unit) -> bool:
	var enemy_units: Array[Unit] = []
	if moving_unit.is_enemy:
		enemy_units = UnitManager.instance.get_player_units()
	else:
		enemy_units = UnitManager.instance.get_enemy_units()
	
	for enemy in enemy_units:
		var enemy_pos: GridPosition = enemy.get_grid_position()
		if abs(enemy_pos.x - grid_pos.x) <= 1 and abs(enemy_pos.z - grid_pos.z) <= 1:
			return true
	return false



func can_activate(_event: ActivationEvent) -> bool:
	if !super.can_activate(_event):
		return false

	var valid_grid_position_list: Array[GridPosition] = await get_valid_move_target_grid_position_list(_event)
	for x: GridPosition in valid_grid_position_list:
		if x._equals(_event.target_grid_position):
			return true
	return false



## Gets the tiles the character can move to, filtering out the ones that couldn't be reached.
func get_valid_move_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.unit
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []
	
	if CombatSystem.instance.engagement_system.is_unit_engaged(in_unit):
		return []
	
	var valid_positions: Array[GridPosition] = []
	#var max_range: float = float(max_move_distance) if use_max_move_distance else in_unit.get_max_move_left()
	
	var max_range: float = movement_left
	
	var temp_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(UnitManager.instance.get_enemy_positions(in_unit))
	
	var proc: int = 0
	# Standard behavior for non-cone-based movement
	for x in range(-max_range, max_range + 1):
		for z in range(-max_range, max_range + 1):
			proc += 1
			if proc >= proc_count:
				await Utilities.get_tree().process_frame
				proc = 0
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
	
	Pathfinding.instance.reenable_positions(temp_disabled)
	
	return valid_positions
