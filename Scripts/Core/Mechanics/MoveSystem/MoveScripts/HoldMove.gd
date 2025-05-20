class_name HoldMove
extends Move



 

var event: ActivationEvent = null
var target_position: GridPosition = null
var unit: Unit = null





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


	
	#if unit.current_gait >= Utilities.MovementGait.RUN or became_engaged:
		#unit.animator.rotate_unit_towards_facing(unit.facing)
	unit.animator.rotate_unit_towards_facing(unit.facing)
	
	if can_end(event):
		event.successful = true
		unit.increase_initiative_score(action_speed)
		end_move(event)
	



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

	
	var valid_positions: Array[GridPosition] = [self_unit_pos]

	
	return valid_positions
