class_name WithdrawEffect extends SpecialEffect

"""
Description:
	The defender may automatically withdraw out of reach, breaking
off engagement with that particular opponent.

"""


@export var max_move_distance: int = 3
@export var use_max_move_distance: bool = false
@export var rotate_speed: float = 4.0  ## Speed for rotating the unit
@export var move_speed: float = 5.5
@export var stopping_distance: float = 0.1
@export var acceleration_timer: float = 0.5  ## Half-second to accelerate movement speed

var target_grid_position: GridPosition = null

func can_activate(event: ActivationEvent) -> bool:
	if !super.can_activate(event):
		return false
	
	if get_valid_ability_target_grid_position_list(event).is_empty():
		return false
	
	
	return true

func on_activated(_event: ActivationEvent) -> void:
	target_grid_position = await handle_move_select(_event)

func can_apply(event: ActivationEvent) -> bool:
	if !super.can_apply(event):
		return false
	
	
	
	return true




func apply(event: ActivationEvent) -> void:
	super.apply(event)
	
	if target_grid_position == null:
		return
	
	
	
	var unit = event.target_unit


	#target_grid_position = await handle_move_select(event)
	
	#await unit.get_tree().create_timer(0.5).timeout
	
	await unit.animator.move_and_slide(target_grid_position, 0.5)
	



	
	



func handle_move_select(event: ActivationEvent) -> GridPosition:
	# Only cardinal directions allowed, no diagonal
	var gridpos_allowed: Array[GridPosition] = get_valid_ability_target_grid_position_list(event)
	var gridpos_choice: GridPosition = await UnitActionSystem.instance.handle_ability_sub_gridpos_choice(gridpos_allowed)
	return gridpos_choice



func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var in_unit: Unit = _event.target_unit
	if !CombatSystem.instance.engagement_system.is_unit_engaged(in_unit):
		return []
	var self_unit_pos: GridPosition = in_unit.get_grid_position()
	if self_unit_pos == null:
		return []
	var move_rate: float = in_unit.attribute_map.get_attribute_by_name("movement_rate").current_modified_value

	# Use half of the unit's remaining movement range.
	var max_range: float = move_rate / 2.0
	var valid_positions: Array[GridPosition] = []
	
	# Determine an integer range (in grid cells) to check.
	var range_int: int = int(ceil(max_range))
	var enemy_positions: Array[GridPosition] = UnitManager.instance.get_enemy_positions(in_unit)
	var adjacent_to_enemy_position: Array[GridPosition] = UnitManager.instance.get_enemy_adjacent_positions(in_unit)
	var actually_disabled: Array[GridPosition] = Pathfinding.instance.temporarily_disable(enemy_positions)
	for x in range(-range_int, range_int + 1):
		for z in range(-range_int, range_int + 1):
			var candidate: GridPosition = LevelGrid.grid_system.get_grid_position_from_coords(
				self_unit_pos.x + x,
				self_unit_pos.z + z
			)
			if candidate and LevelGrid.is_valid_grid_position(candidate):
				# Exclude positions that already contain an enemy.
				if not LevelGrid.has_any_unit_on_grid_position(candidate) and !adjacent_to_enemy_position.has(candidate):
					# Ensure the candidate is walkable.
					if Pathfinding.instance.is_walkable(candidate):
						var path: Array[GridPosition] = Pathfinding.instance.find_path(self_unit_pos, candidate)
						if path.size() > 0:
							var cost: float = Pathfinding.instance.get_path_cost(self_unit_pos, candidate)
							if cost <= max_range and cost < INF:
								valid_positions.append(candidate)
	Pathfinding.instance.reenable_positions(actually_disabled)
	return valid_positions
