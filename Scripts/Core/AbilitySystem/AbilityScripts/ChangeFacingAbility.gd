@tool
class_name ChangeFacingAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_group("Attributes")
@export var ap_cost: int = 0
## The movement cost to turn when running or sprinting
@export var movement_cost: float = 2.0

var event: ActivationEvent = null
var unit: Unit = null
var gait: int

# NOTE: Logic for which parry animation to use will go here, depends on character and weapon.
# By default will use strike animation.


func try_activate(_event: ActivationEvent) -> void:
	#super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	unit = event.unit
	if not unit:
		if can_end(event):
			push_error("no unit: " + event.to_string())
			end_ability(event)
			return
	gait = unit.current_gait
	
	var facing: int = check_desired_facing()
	if facing == -1:
		if can_end(event):
			push_error("Invalid Facing on: " + unit.name)
			end_ability(event)
			return
	add_distance()
	rotate_unit_towards_target_facing(facing) #takes an int of the facing(0, 1, 2, or 3)
	await unit.animator.rotation_completed # Always be careful to wait for the animation to complete

	
	if can_end(event):
		event.successful = true
		end_ability(event)



#this function is supposed to return the facing that the unit wants to turn towards based off of the target position fed.
func check_desired_facing() -> int:
	var grid_position: GridPosition = event.target_grid_position
	var unit_position: GridPosition = unit.get_grid_position()
	if grid_position.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x, unit_position.z - 1)):
		return Utilities.FACING.NORTH
	elif grid_position.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x + 1, unit_position.z)):
		return Utilities.FACING.EAST
	elif grid_position.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x, unit_position.z + 1)):
		return Utilities.FACING.SOUTH
	elif grid_position.equals(LevelGrid.grid_system.get_grid_position_from_coords(unit_position.x - 1, unit_position.z)):
		return Utilities.FACING.WEST

	push_error("Invalid grid position on ", event.unit)
	return -1


func rotate_unit_towards_target_facing(facing: int) -> void:
	unit.set_facing_then_rotate(facing)


func add_distance() -> void:
	if (unit.current_gait >= Utilities.MovementGait.RUN):
		if event.target_grid_position.equals(Utilities.get_back_tile(unit)):
			unit.add_distance_moved(movement_cost * 2)
			return
		unit.add_distance_moved(movement_cost)


func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false
	
	var valid_positions: Array[GridPosition] = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false


## Gets a list of valid grid positions for facing or moving.
## This version checks:
##  1) Are we hold/walk or run/sprint?
##  2) Do we have enough movement left to face (especially if behind us)?
##  3) Exclude the direct front tile if that's desired by design.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var character: Unit = _event.unit
	var candidate_positions: Array[GridPosition] = Utilities.get_adjacent_tiles_no_diagonal(character)
	var final_positions: Array[GridPosition] = []

	# --- 1) If we are HOLD GROUND or WALK, we skip the movement-cost checks. ---
	if character.current_gait < Utilities.MovementGait.RUN:
		# Just exclude the front tile if your design wants that restriction:
		for pos in candidate_positions:
			if pos != Utilities.get_front_tile(character):
				final_positions.append(pos)

	# --- 2) If we are RUNNING or SPRINTING, apply the movement-cost checks. ---
	else:
		var dist: float = character.distance_moved_this_turn
		var move_rate: float = character.get_movement_rate()
		var move_gait: int = character.current_gait

		# Determine speed multiplier (RUN vs. SPRINT):
		var speed_multiplier: float = Utilities.GAIT_SPEED_MULTIPLIER[move_gait]  # e.g. 3.0 or 5.0
		var max_move_left: float = ((move_rate * speed_multiplier)/2.0) - dist

		for pos in candidate_positions:
			if pos != Utilities.get_front_tile(character):
				# Base cost to face/move to tile
				var cost: float = movement_cost

				# Double the cost if it's the back tile:
				if pos.equals(Utilities.get_back_tile(character)):
					cost *= 2.0

				# Only add this position if we can afford it:
				if max_move_left >= cost:
					final_positions.append(pos)

	return final_positions




## Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
