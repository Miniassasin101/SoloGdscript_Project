@tool
class_name OutmaneuverAbility extends Ability

@export_group("Attributes")
@export var ap_cost: int = 1


@export var max_move_distance: int = 3
@export var use_max_move_distance: bool = false
@export var rotate_speed: float = 4.0  ## Speed for rotating the unit
@export var move_speed: float = 5.5
@export var stopping_distance: float = 0.1
@export var acceleration_timer: float = 0.5  ## Half-second to accelerate movement speed

var event: ActivationEvent = null
var unit: Unit = null



func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	unit = event.unit
	if not unit or not event.target_grid_position:
		push_error("OutmaneuverAbility: Missing unit or target grid position.")
		end_ability(event)
		return
	
	# Validate the chosen target position.
	if not can_activate(event):
		push_error("OutmaneuverAbility: Target grid position is invalid.")
		end_ability(event)
		return
	
	# Gather engaged opponents from CombatSystem.engagements.
	var engaged_opponents: Array[Unit] = []
	for engagement in CombatSystem.instance.engagements:
		if engagement.units.has(unit):
			for other_unit in engagement.units:
				if other_unit != unit and not engaged_opponents.has(other_unit):
					engaged_opponents.append(other_unit)
	
	# Perform opposed rolls against each engaged opponent.
	var user_roll = Utilities.roll(100)
	var success = true
	for opponent in engaged_opponents:
		var opponent_roll = Utilities.roll(100)
		print_debug("Outmaneuver: " + unit.ui_name + " rolled " + str(user_roll) + " vs. " + opponent.ui_name + " rolled " + str(opponent_roll))
		if user_roll <= opponent_roll:
			Utilities.spawn_text_line(unit, "Outmaneuver Failed", Color.FIREBRICK)
			success = false
			event.successful = true
			if can_end(event):
				end_ability(event)
				return
		else:
			Utilities.spawn_text_line(unit, "Outmaneuvered", Color.AQUA)
	
	# Now move the unit along the full path (like MoveAbility, but without trimming)

	var path_package: PathPackage = Pathfinding.instance.get_path_package(event.target_grid_position, unit, true, true)
	var grid_position_list: Array[GridPosition] = path_package.get_path()
	if grid_position_list.is_empty():
		push_error("No valid path found to target position: " + event.target_grid_position.to_str())
		end_ability(event)
		return
	
	# Unlike MoveAbility, do not trim the path; use the full path.
	var position_list = LevelGrid.get_world_positions(grid_position_list)
	
	# Create the movement curve.
	var movement_curve = Curve3D.new()
	movement_curve.bake_interval = 0.2  # Adjust for smoothness
	
	for i in range(position_list.size()):
		var point = position_list[i]
		var control_offset = Vector3(0, 0, 0)
		if i > 0 and i < position_list.size() - 1:
			control_offset = (position_list[i + 1] - position_list[i - 1]).normalized() * 0.5
		movement_curve.add_point(point, -control_offset, control_offset)
	
	var curve_length = movement_curve.get_baked_length()
	var curve_travel_offset = 0.0
	var acceleration_timer = 0.2
	var rotation_acceleration_timer = 0.3
	var current_speed = 0.1
	var start_timer = 0.1


	unit.animator.animate_movement_along_curve(move_speed, movement_curve, curve_length, 
		acceleration_timer, rotation_acceleration_timer, stopping_distance, rotate_speed)
	await unit.animator.movement_completed  # Wait until movement finishes
	
	# Optionally recalc path cost based on full path.
	# Temportarily commented out for outmaneuver.
	#var final_cost = Pathfinding.instance.get_path_cost(unit.get_grid_position(), grid_position_list[grid_position_list.size() - 1])
	#unit.add_distance_moved(final_cost)
	
	#if unit.current_gait >= Utilities.MovementGait.RUN:
	#	unit.animator.rotate_unit_towards_facing(unit.facing)
	
	
	# Finally, set the event's success based on the opposed rolls.
	if success:
		event.successful = true
	else:
		event.successful = false
	

	
	await handle_turning()
	

	
	if can_end(event):
		end_ability(event)



func handle_turning() -> void:
	# Only cardinal directions allowed, no diagonal
	var gridpos_allowed: Array[GridPosition] = Utilities.get_adjacent_tiles_no_diagonal(unit)
	var gridpos_choice: GridPosition = (
		await UnitActionSystem.instance.handle_ability_sub_gridpos_choice(gridpos_allowed))
	
	var facing: int = check_desired_facing(gridpos_choice)
	if facing == -1:
		if can_end(event):
			push_error("Invalid Facing on: " + unit.name)
			end_ability(event)
			return
	
	unit.set_facing_then_rotate(facing) # Takes an int of the facing(0, 1, 2, or 3)
	await unit.animator.rotation_completed # Always be careful to wait for the animation to complete



# This function is supposed to return the facing that the unit wants to turn towards based off of the target position fed.
func check_desired_facing(target_facing_pos: GridPosition) -> int:
	var unit_position: GridPosition = unit.get_grid_position()
	if target_facing_pos.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x, unit_position.z - 1)):
		return Utilities.FACING.NORTH
	elif target_facing_pos.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x + 1, unit_position.z)):
		return Utilities.FACING.EAST
	elif target_facing_pos.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x, unit_position.z + 1)):
		return Utilities.FACING.SOUTH
	elif target_facing_pos.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x - 1, unit_position.z)):
		return Utilities.FACING.WEST

	push_error("Invalid grid position on ", event.unit)
	return -1






func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.unit
	if !CombatSystem.instance.is_unit_engaged(in_unit):
		return []
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []
	var move_rate: float = in_unit.attribute_map.get_attribute_by_name("movement_rate").current_buffed_value

	# Use half of the unit's remaining movement range.
	var max_range: float = move_rate / 2.0
	var valid_positions: Array[GridPosition] = []
	
	# Determine an integer range (in grid cells) to check.
	var range_int: int = int(ceil(max_range))
	var enemy_positions: Array[GridPosition] = UnitManager.instance.get_enemy_positions(in_unit)
	var actually_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(enemy_positions)
	for x in range(-range_int, range_int + 1):
		for z in range(-range_int, range_int + 1):
			var candidate: GridPosition = LevelGrid.grid_system.get_grid_position_from_coords(
				self_unit_pos.x + x,
				self_unit_pos.z + z
			)
			if candidate and LevelGrid.is_valid_grid_position(candidate):
				# Exclude positions that already contain an enemy.
				if not LevelGrid.has_any_unit_on_grid_position(candidate):
					# Ensure the candidate is walkable.
					if Pathfinding.instance.is_walkable(candidate):
						var path: Array[GridPosition] = Pathfinding.instance.find_path(self_unit_pos, candidate)
						if path.size() > 0:
							var cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, candidate)
							if cost <= max_range and cost < INF:
								valid_positions.append(candidate)
	Pathfinding.instance.reenable_positions(actually_disabled)
	return valid_positions

# --- Utility Functions --- 


# --- Dummy prompt for facing selection ---
# In a full implementation, this would trigger UI for the player to choose a direction.
func prompt_direction() -> int:
	# Wait a short time and then return 0 (representing North).
	await unit.get_tree().create_timer(0.5).timeout
	return 0
