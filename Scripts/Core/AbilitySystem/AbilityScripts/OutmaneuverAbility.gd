@tool
class_name OutmaneuverAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_group("Condition")
@export var outmaneuvered_condition: OutmaneuveredCondition = null

@export_group("Attributes")
@export var ap_cost: int = 1

@export var max_move_distance: int = 3
@export var use_max_move_distance: bool = false
@export var rotate_speed: float = 4.0  ## Speed for rotating the unit
@export var move_speed: float = 5.5
@export var stopping_distance: float = 0.1
#@export var acceleration_timer: float = 0.5  ## Half-second to accelerate movement speed

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
	var engaged_opponents: Array[Unit] = CombatSystem.instance.engagement_system.get_engaged_opponents(unit)


	# Determine if there is at least one other engaged enemy (besides the one being processed).
	var extraEnemyEngaged: bool = engaged_opponents.size() > 1

	# Fetch an existing DynamicButtonPicker in the scene tree.
	var dynamic_picker: DynamicButtonPicker = UILayer.instance.unit_action_system_ui.dynamic_button_picker
	if dynamic_picker == null:
		push_error("No DynamicButtonPicker in scene. Please instance or reference it properly.")
		return

	# Perform opposed rolls against each engaged opponent.
	var user_roll = Utilities.roll(100)
	var user_evade: int = unit.get_attribute_after_sit_mod("evade_skill")
	var user_success: int = Utilities.check_success_level(user_evade, user_roll)
	
	var success = false

	# Loop through each engaged opponent.
	for opponent in engaged_opponents:

		# ----- NEW: Check if the opponent has 0 AP. Automatically fail if so.
		if opponent.get_ability_points() <= 0:
			if extraEnemyEngaged:
				Utilities.spawn_text_line(opponent, "Outmaneuvered", Color.FIREBRICK)
				var cond_no_ap: OutmaneuveredCondition = outmaneuvered_condition.duplicate()
				cond_no_ap.outmaneuvering_units.append(unit)
				opponent.conditions_manager.add_condition(cond_no_ap)
			# Skip dynamic picker prompt if AP is insufficient.
			continue

		# Prompt the opponent for block decision.
		dynamic_picker.pick_options(["Block", "Don't Block"])
		GridSystemVisual.instance.hide_all_grid_positions() 
		GridSystemVisual.instance.show_grid_positions([opponent.get_grid_position()])
		var choice: String = await dynamic_picker.option_selected

		if choice == "Block" and opponent.get_ability_points() > 0:
			# Opponent has opted to block; they must spend 1 AP.
			if opponent.can_spend_ability_points_to_use_ability(self):
				opponent.spend_ability_points(1)
				var opponent_roll: int = Utilities.roll(100)
				var opponent_evade: int = opponent.get_attribute_after_sit_mod("evade_skill")
				var opponent_success: int = Utilities.check_success_level(opponent_evade, opponent_roll)
				print_debug("Outmaneuver: " + unit.ui_name + " rolled " + str(user_roll) + " vs. " + opponent.ui_name + " rolled " + str(opponent_roll))
				
				print_debug("User Success: " + str(user_success))
				print_debug("Opponent Success: " + str(opponent_success))
				# If opponent’s roll is greater than or equal to the outmaneuverer’s roll, block succeeds.
				if opponent_success > user_success:
					Utilities.spawn_text_line(opponent, "Block Successful", Color.AQUA)
					print_debug("Opponent Success Was Greater")
					success = true
					continue
					
				if opponent_roll < user_roll:
					Utilities.spawn_text_line(opponent, "Block Successful", Color.AQUA)
					print_debug("Opponent Roll Was Lower")
					success = true
				else:
					Utilities.spawn_text_line(opponent, "Block Failed", Color.ORANGE)
					
					# Opponent failed the opposed roll—apply Outmaneuvered Condition if another enemy is engaged.
					if extraEnemyEngaged:
						Utilities.spawn_text_line(opponent, "Outmaneuvered", Color.FIREBRICK)
						var cond: OutmaneuveredCondition = outmaneuvered_condition.duplicate()
						cond.outmaneuvering_units.append(unit)
						opponent.conditions_manager.add_condition(cond)
			else:
				# Not enough AP to block; automatically fail the block.
				if extraEnemyEngaged:
					Utilities.spawn_text_line(opponent, "Outmaneuvered", Color.FIREBRICK)
					var cond_insufficient: OutmaneuveredCondition = outmaneuvered_condition.duplicate()
					cond_insufficient.outmaneuvering_units.append(unit)
					opponent.conditions_manager.add_condition(cond_insufficient)
		else:  # Opponent chooses "Don't Block"
			# Automatically treat as block failure.
			if extraEnemyEngaged:
				Utilities.spawn_text_line(opponent, "Outmaneuvered", Color.FIREBRICK)
				var cond_ignore: OutmaneuveredCondition = outmaneuvered_condition.duplicate()
				cond_ignore.outmaneuvering_units.append(unit)
				opponent.conditions_manager.add_condition(cond_ignore)

		# Small delay between processing each opponent.
		await opponent.get_tree().create_timer(0.1).timeout

	# If any opponent successfully blocked, mark the event as successful and exit early.
	if success:
		event.successful = true
		if can_end(event):
			end_ability(event)
			return

	# Continue with unit movement. (Movement code remains as in your original script.)
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
	var acceleration_timer = 0.2
	var rotation_acceleration_timer = 0.3

	unit.animator.animate_movement_along_curve(move_speed, movement_curve, curve_length, 
		acceleration_timer, rotation_acceleration_timer, stopping_distance, rotate_speed)
	await unit.animator.movement_completed  # Wait until movement finishes

	# Handle turning and finalize ability.
	await handle_turning()

	event.successful = true
	if can_end(event):
		end_ability(event)


func handle_turning() -> void:
	# Only cardinal directions allowed, no diagonal
	var gridpos_allowed: Array[GridPosition] = Utilities.get_adjacent_tiles_no_diagonal(unit)
	var gridpos_choice: GridPosition = (await UnitActionSystem.instance.handle_ability_sub_gridpos_choice(gridpos_allowed))
	var facing: int = check_desired_facing(gridpos_choice)
	if facing == -1:
		if can_end(event):
			push_error("Invalid Facing on: " + unit.name)
			end_ability(event)
			return
	unit.set_facing_then_rotate(facing)
	await unit.animator.rotation_completed


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
	if not CombatSystem.instance.engagement_system.is_unit_engaged(in_unit):
		return []
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []
	var move_rate: float = in_unit.attribute_map.get_attribute_by_name("movement_rate").current_buffed_value

	# Use half of the unit's remaining movement range.
	var max_range: float = move_rate / 2.0
	var valid_positions: Array[GridPosition] = []
	
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
				if not LevelGrid.has_any_unit_on_grid_position(candidate):
					if Pathfinding.instance.is_walkable(candidate):
						var path: Array[GridPosition] = Pathfinding.instance.find_path(self_unit_pos, candidate)
						if path.size() > 0:
							var cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, candidate)
							if cost <= max_range and cost < INF:
								valid_positions.append(candidate)
	Pathfinding.instance.reenable_positions(actually_disabled)
	return valid_positions

func prompt_direction() -> int:
	await unit.get_tree().create_timer(0.5).timeout
	return 0
