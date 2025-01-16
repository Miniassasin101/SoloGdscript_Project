@tool
class_name ChangeFacingAbility extends Ability

## Example tooltip comment, put directly above the line(s) they reference

@export_group("Attributes")
@export var ap_cost: int = 0


var event: ActivationEvent = null
var unit: Unit = null
var gait: int
# NOTE: Logic for which parry animation to use will go here, depends on character and weapon.
# By default will use strike animation.


func try_activate(_event: ActivationEvent) -> void:
	super.try_activate(_event)
	event = _event
	# Retrieve target position from the event
	unit = event.character
	if not unit:
		if can_end(event):
			push_error("no unit: " + event.to_string())
			end_ability(event)
			return
	gait = unit.current_gait

	rotate_unit_towards_target_enemy(event)


#func prompt_facing#



func rotate_unit_towards_target_enemy(_event: ActivationEvent) -> void:
	var animator: UnitAnimator = unit.animator
	animator.rotate_unit_towards_target_position(event.target_grid_position)
	await animator.rotation_completed
	var timer = Timer.new()
	
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 0.5

	event.character.add_child(timer)
	await timer.timeout
	if can_end(event):
		end_ability(event)







func can_activate(_event: ActivationEvent) -> bool:
	if not super.can_activate(_event):
		return false

	# We get all valid target squares in range, then check if the event target is among them.
	var valid_positions = get_valid_ability_target_grid_position_list(_event)
	for pos in valid_positions:
		if pos._equals(_event.target_grid_position):
			return true
	return false


## Gets a list of valid grid positions for facing.\n
## Should be the positions directly in front of, behind, and to the side of the unit.
func get_valid_ability_target_grid_position_list(_event: ActivationEvent) -> Array[GridPosition]:
	var valid_grid_position_list: Array[GridPosition] = []

	# Get the unit's current grid position.
	var current_position = _event.character.get_grid_position()

	# Define the relative offsets for adjacent positions (up, down, left, right).
	var offsets = [
		GridPosition.new(0, 1),   # Up
		GridPosition.new(0, -1),  # Down
		GridPosition.new(-1, 0),  # Left
		GridPosition.new(1, 0)    # Right
	]

	# Check each adjacent position.
	for offset in offsets:
		var candidate_position = current_position.add(offset)

		# Ensure the candidate position is valid in the LevelGrid.
		if not LevelGrid.is_valid_grid_position(candidate_position):
			continue

		valid_grid_position_list.append(candidate_position)

	return valid_grid_position_list



# Gets the best AI action for a specified grid position.
func get_enemy_ai_ability(_event: ActivationEvent) -> EnemyAIAction:
	var enemy_ai_ability: EnemyAIAction = EnemyAIAction.new()
	enemy_ai_ability.action_value = 30
	enemy_ai_ability.grid_position = _event.target_grid_position
	return enemy_ai_ability
